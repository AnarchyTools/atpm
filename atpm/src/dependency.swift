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
import atpkg
import atfoundation
import atpm_tools

///Choose a version
///- parameter versions: The set of legal versions we could choose
///- parameter versionRange: Version specifiers such as are provided in a build.atpkg
///- parameter lockedPayload: Use this payload to choose a version if possible
///- parameter update: Whether to update the package, or only fetch
func chooseVersion(versions: [Version], versionRange: VersionRange, lockedPayload: LockedPayload?, update: Bool) throws -> Version? {
    if lockedPayload?.pinned == true || !update {
        if let v = lockedPayload?.usedVersion {
            guard let lockedVersion = try versions.filter({ version throws -> Bool in
                return version.description == v
            }).first else {
                fatalError("Can't find version \(v) to fetch.  Use update and/or unpin to resolve.")
            }
            return lockedVersion
        }
    }
    var versions = versions
    versions = try versions.filter { version throws -> Bool in
        return versionRange.versionInRange(version)
    }

    versions.sort(isOrderedBefore: { (v1, v2) -> Bool in
        return v1 < v2
    })

    if versions.count > 0 {
        print("Valid versions: \(versions), using \(versions.last!)")
        return versions.last!
    } else {
        print("No valid versions!")
        return nil
    }
}

func updateDependency(_ pkg: ExternalDependency, lock: LockedPackage?, firstTime: Bool = false) throws {
    switch(pkg.dependencyType) {
        case .Git:
        try updateGitDependency(pkg, lock: lock, firstTime: firstTime)
        case .Manifest:
        try fetchHTTPDependency(pkg, lock: lock, update: true)
        break
    }
}

//- returns: The name of the depency we downloaded
func fetchDependency(_ pkg: ExternalDependency, lock: LockedPackage?) throws {

    //note that this check only works for git dependencies – 
    //binary dependencies names are defined in the manifest
    if let name = pkg.name {
        if FS.fileExists(path: Path("external/\(name)")) {
            print("Already downloaded")
            return
        }
    }
    
    let ext = Path("external")
    if !FS.fileExists(path: ext) {
        try FS.createDirectory(path: ext)
    }

    switch(pkg.dependencyType) {
        case .Git:
        try fetchGitDependency(pkg, lock: lock)

        case .Manifest:
        try fetchHTTPDependency(pkg, lock: lock, update: false)
    }


}

