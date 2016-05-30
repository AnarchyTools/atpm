// Copyrhs (c) 2016 Anarchy Tools Contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import atfoundation
import atpkg
import atpm_tools

///We populate the _applicationInfo with this value
///Basically, although via the git architecture it's pretty easy to find out what git we checked out (just inspect the commit)
///Doing that for binaries is too complicated.  We don't remember where the tarball is, we don't remember what its shasum was, etc.
///So instead, we build one of these during the binary fetch process and then use it when we write the lockfile
struct HTTPDependencyInfo {
    let channels: [HTTPDependencyChannel]
}

struct HTTPDependencyChannel {
    let lockedPayload: LockedPayload
    let channel: String
}

///The world's most terrible HTTP implementation
private func fetch(url: URL, to file: Path) throws {
    if url.schema != "https" { throw PMError.InsecurePackage }
    let curlResult = system("curl -sL -o '\(file)' '\(url)'")
    if curlResult != 0 {
        throw PMError.HTTPSTransportError(exitCode: curlResult)
    }
}

func fetchHTTPDependency(_ pkg:ExternalDependency,lock: LockedPackage?) throws {
    print("Fetching HTTP dependency...")
    let manifestPath = try FS.temporaryDirectory().appending("manifest.atpkg")

    try fetch(url: pkg.url, to: manifestPath)
    let parsedManifest = try Package(filepath: manifestPath, overlay: [], focusOnTask: nil)
    pkg._parsedNameFromManifest = parsedManifest.name
    guard let channels = parsedManifest.binaryChannels else { fatalError("No binary channels in manifest ")}
    //what channels should we load?
    let channelsToLoad: [String]
    if let c = pkg.channels {
        //load specified channels
        channelsToLoad = c
    }
    else  { 
        //load all available channel
        channelsToLoad = channels.map({$0.name}) 
    }
    var httpChannels : [HTTPDependencyChannel] = []
    for channel in channelsToLoad {
        //load channel
        guard let parsedChannel = channels.filter({$0.name == channel}).first else {
            fatalError("Can't find channel named \(channel) in channels")
        }
        //parse version range from build.atpkg
        guard case .Version(let versionSpecifications) = pkg.version else {
            fatalError("Only `version` supported in binary specification.  Actual: \(pkg.version)")
        }
        let versionRange = VersionRange()
        for ver in versionSpecifications {
            try versionRange.combine(ver)
        }
        //parse versions from manifest
        var versions: [Version] = []
        for manifestVersion in parsedChannel.versions {
            let atpmVersion = Version(string: manifestVersion.version)
            versions.append(atpmVersion)
        }
        
        //figure out which version we need to load
        guard let versionToLoad = try chooseVersion(versions: versions, versionRange: versionRange) else {
            fatalError("Can't find a version matching \(versionRange) in \(versions)")
        }
        
        let binaryVersion = parsedChannel.versions.filter({$0.version == versionToLoad.description}).first!
        print("Fetching \(binaryVersion.url)")
        let packagePath = Path("external/\(parsedManifest.name)")
        let tarballPath = packagePath.appending("\(binaryVersion.url.path.basename())")
        if FS.fileExists(path: tarballPath) { try FS.removeItem(path: tarballPath)}
        if !FS.fileExists(path: packagePath) { try FS.createDirectory(path: packagePath) }
        try fetch(url: binaryVersion.url, to: tarballPath)
        if tarballPath.description.hasSuffix("tar.xz") {
            print("Expanding tarball...")
            let result = system("tar xf \(tarballPath) -C \(packagePath)")
            if result != 0 {
                throw PMError.TarError(exitCode: result)
            }
        }

        //load the payload out of the lock file if it already exists
        var lockedPayload: LockedPayload
        if let lp = lock?.payloadMatching(key: channel) { lockedPayload = lp}
        else {lockedPayload = LockedPayload(key: channel)}

        lockedPayload.usedVersion = versionToLoad.description
        lockedPayload.usedURL = binaryVersion.url.description
        lockedPayload.shaSum = getSHASum(path: tarballPath)

        //copy payload to applicationInfo
        let httpInfo = HTTPDependencyChannel(lockedPayload: lockedPayload, channel: channel)
        httpChannels.append(httpInfo)
    }
    pkg._applicationInfo = HTTPDependencyInfo(channels: httpChannels)
}

private func getSHASum(path: Path) -> String {
    let fp = popen("shasum -a 256 -b \(path) | cut -d ' ' -f 1 ", "r")
    guard fp != nil else {
        fatalError("fp is nil")
    }
    defer {
        pclose(fp)
    }
    var buffer = [CChar](repeating: 0, count: 255)
    while feof(fp) == 0 {
        if fgets(&buffer, 255, fp) == nil {
            break
        }
        if let shasum = String(validatingUTF8: buffer) {
            //chop off \n
            return String(shasum.characters[shasum.characters.startIndex..<shasum.characters.index(before: shasum.characters.endIndex)])
        }
    }
    fatalError("Could not calculate shasum for \(path)")
}

