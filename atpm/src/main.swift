// Copyright (c) 2016 Anarchy Tools Contributors.
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

let version = "1.2.3"

import atfoundation
import atpkg
import atpm_tools

let defaultBuildFile = Path("build.atpkg")
let defaultLockFile = Path("build.atlock")


func loadPackageFile() -> Package {
    do {
        return try Package(filepath: defaultBuildFile, overlay: [], focusOnTask: nil, softFail: true)
    } catch {
        print("Unable to load build file '\(defaultBuildFile)': \(error)")
        exit(1)
    }
}

func loadLockFile() -> LockFile? {
    do {
        return try LockFile(filepath: defaultLockFile)
    } catch {
        print("Warning: No lock file loaded '\(defaultLockFile)': \(error)")
        return nil
    }
}

// MARK: - Command handling

func info(_ package: Package, indent: Int = 4) {
    for dep in package.externals {
        var out = ""
        for _ in 0..<indent {
            out += " "
        }
        out += "- \(dep.url)"
        print(out)

        switch(dep.dependencyType) {
            case .Git:
            let subPackagePath = Path("external/\(dep.name)/build.atpkg")
            do {
                let subPackage = try Package(filepath: subPackagePath, overlay: [], focusOnTask: nil, softFail: true)
                info(subPackage, indent: indent + 4)
            } catch {
                out = ""
                for _ in 0..<indent {
                    out += " "
                }
                out += "-> Could not load Package file: \(error)"
                print(out)
            }
            case .Manifest:
            break
        }
        
    }
}

func fetch(_ package: Package, lock: LockFile?) -> [ExternalDependency] {
    var packages = [ExternalDependency]()
    for pkg in package.externals {
        guard pkg.shouldInclude else {
            print ("Not fetching dependency \(pkg.name ?? pkg.url); to fetch, use one of \(pkg.ifIncluding?.description ?? "BUG")")
            continue
        }
        print("Fetching external dependency \(pkg.name ?? "\(pkg.url)")...")
        do {
            try fetchDependency(pkg, lock: lock?[pkg.url])
            switch(pkg.dependencyType) {
                case .Git:
                do {
                    try FS.symlinkItem(from: Path(".."), to: Path("external/\(pkg.name!)/external"))
                }
                catch SysError.FileExists { /* */ }
                let subPackagePath = Path("external/\(pkg.name!)/build.atpkg")

                do {
                    let p = try Package(filepath: subPackagePath, overlay: [], focusOnTask: nil, softFail: true)
                    packages.append(pkg)
                    packages += fetch(p, lock: lock)
                } catch {
                    print("Unable to load build file '\(subPackagePath)': \(error)")
                    continue
                }

                case .Manifest:
                packages.append(pkg)
            }
            
        } catch {
            print("ERROR: Could not fetch \(pkg.url): \(error)")
            exit(1)
        }
    }
    return packages
}

func update(_ package: Package, lock: LockFile?) -> [ExternalDependency] {
    var packages = [ExternalDependency]()

    for pkg in package.externals {
        guard pkg.shouldInclude else {
            print ("Not fetching dependency \(pkg.name ?? pkg.url); to fetch, use one of \(pkg.ifIncluding?.description ?? "BUG")")
            continue
        }
        print("Updating external dependency \(pkg.name ?? pkg.url)...")
        do {
            try updateDependency(pkg, lock: lock?[pkg.url])

            switch(pkg.dependencyType) {
                case .Git:
                do {
                    try FS.symlinkItem(from: Path(".."), to: Path("external/\(pkg.name!)/external"))
                } catch SysError.FileExists {
                    // just ignore this error as the symlink may exist from previous calls
                }
                let subPackagePath = Path("external/\(pkg.name!)/build.atpkg")
                do {
                    let p = try Package(filepath: subPackagePath, overlay: [], focusOnTask: nil, softFail: true)
                    packages.append(pkg)
                    packages += update(p, lock: lock)
                } catch {
                    print("Unable to load build file '\(subPackagePath)': \(error)")
                }

                case .Manifest:
                packages.append(pkg)
            }
            
        } catch {
            print("ERROR: Could not update \(pkg.name!): \(error)")
            return packages
        }
    }
    return packages
}

/// - paramater pinned: true if being pinned, false if being unpinned
func pinStatus(_ package: Package, lock: LockFile?, name: String, pinned: Bool) -> [ExternalDependency] {
    var packages = [ExternalDependency]()
    let lockFile: LockFile = lock ?? LockFile()

    for pkg in package.externals {
        switch(pkg.dependencyType) {
            case .Git:
            let subPackagePath = Path("external/\(pkg.name!)/build.atpkg")
            do {
                let p = try Package(filepath: subPackagePath, overlay: [], focusOnTask: nil)
                packages.append(pkg)
                packages += pinStatus(p, lock: lock, name: name, pinned: pinned)
            } catch {
                print("Unable to load build file '\(subPackagePath)': \(error)")
            }

            case .Manifest:
            packages.append(pkg)
        }   
    }

    //vend an inner func to do the match check
    func packageMatches(lockFile: LockFile, package: ExternalDependency, name: String) -> (LockedPayload, LockedPackage)? {
        var lockedPackage = lockFile[package.url]!
        switch(package.dependencyType) {
            case .Git:
            if package.name == name { return (lockedPackage.gitPayload, lockedPackage) }

            case .Manifest:
            if !name.contains(character: ".") {
                fatalError("Use package.channel syntax when pinning a binary package, not \(name)")
            }
            let actualPackageName = name.split(character: ".")[0]
            let actualChannelName = name.split(character: ".")[1]
            if package.name! == actualPackageName {
                defer {lockFile[package.url] = lockedPackage}
                let payload = lockedPackage.createPayloadMatching(key: actualChannelName)
                return (payload, lockedPackage)
            }
        }
        return nil
    }

    for pkg in packages {
        //manifest packages need to be fetched so as to resolve their names
        if pkg.dependencyType == .Manifest {
            let _ = try! fetchHTTPManifestOnly(pkg)
        }
        if var (payload, package) = packageMatches(lockFile: lockFile, package: pkg, name: name) {
            if pinned {
                payload.pinned = true
                print("pinning \(payload)")
            } else {
                payload.pinned = false
            }
            //update containing structs
            package.setPayload(payload)
            lockFile[pkg.url] = package
        }
    }

    return packages
}

func overrideURL(_ package: Package, lock: LockFile?, name: String, newURL: String?) -> [ExternalDependency] {
    var packages = [ExternalDependency]()
    let lockFile: LockFile = lock ?? LockFile()

    for pkg in package.externals {
        let subPackagePath = Path("external/\(pkg.name!)/build.atpkg")
        do {
            let p = try Package(filepath: subPackagePath, overlay: [], focusOnTask: nil, softFail: true)
            packages.append(pkg)
            packages += overrideURL(p, lock: lock, name: name, newURL: newURL)
        } catch {
            print("Unable to load build file '\(subPackagePath)': \(error)")
        }
    }
    for pkg in packages {
        if pkg.name == name {
            var lockedPackage = lockFile[pkg.url]!
            lockedPackage.gitPayload.overrideURL = newURL
            lockFile[pkg.url] = lockedPackage
        }
    }

    return packages
}

func writeLockFile(_ packages: [ExternalDependency], lock: LockFile?) {
    let lockFile: LockFile = lock ?? LockFile()

    var newPackages = [LockedPackage]()

    let lockPkgs = lockFile.packages
    for pkg in packages {

        //look for an existing lockedPackage in our list

        //swift can't infer the single assignment here
        var lockedPackage : LockedPackage
        var _lockedPackage : LockedPackage! = nil
        for lockedPkg in lockPkgs {
            if lockedPkg.url == pkg.url {
                _lockedPackage = lockedPkg
            }
        }
        if let lp = _lockedPackage {
            lockedPackage = lp
        }
        else {
            switch(pkg.dependencyType) {
                case .Git:
                lockedPackage = LockedPackage(url: pkg.url, payloads:[LockedPayload(key: "git")])
                case .Manifest:
                lockedPackage = LockedPackage(url: pkg.url, payloads: [])
            }
        }

        switch(pkg.dependencyType) {
            case .Git:
            updateGitLockPackage(pkg: pkg, lockedPackage: &lockedPackage)

            case .Manifest:
            //Pull the payloads out of the pkg._applicationInfo
            //This is set when the dependency was fetched
            if let info = pkg._applicationInfo as? HTTPDependencyInfo {
                //Overwrite all existing payloads
                lockedPackage.payloads = []
                for payload in info.channels {
                    lockedPackage.payloads.append(payload.lockedPayload)
                }
            }


            break
        }


        //foo

        newPackages.append(lockedPackage)
    }
    lockFile.packages = newPackages
    let string = lockFile.serialize()
    do {
        try string.write(to: defaultLockFile)
    } catch {
        print("ERROR: Could not write lock file \(defaultLockFile)")
    }
}

func help() {
    print("atpm - Anarchy Tools Package Manager \(version)")
    print("https://github.com/AnarchyTools")
    print("© 2016 Anarchy Tools Contributors.")
    print()
    print("Usage: atpm [command]")
    print()
    print("    info")
    print("        show information for all package dependencies")
    print()
    print("    fetch")
    print("        fetch new packages, does not touch already fetched packages")
    print()
    print("    update")
    print("        update already fetched packages (if they are not pinned)")
    print()
    print("    pin <package-name>")
    print("        pin current package status of <package-name> and record in lock file")
    print()
    print("    unpin <package-name>")
    print("        unpin status of <package-name>")
    print()
    print("    override <package-name> <new-url>")
    print("        override git url of <package-name> to <new-url>")
    print()
    print("    restore <package-name>")
    print("        remove git url override of <package-name>")
    print()
}

//usage message
if CommandLine.arguments.contains("--help") {
    help()
    exit(0)
}

// MARK: - Argument handling

let package = loadPackageFile()
let lockFile = loadLockFile()

guard CommandLine.arguments.count > 1 else {
    help()
    exit(1)
}

switch CommandLine.arguments[1] {
case "info":
    print("Dependencies:")
    info(package)
    exit(0)
case "fetch":
    let packages = fetch(package, lock: lockFile)
    if packages.count > 0 {
        if let conflicts = validateVersions(packages: packages) {
            print("Can not solve the version graph. The following conflicts were detected:")
            for (package, versions) in conflicts {
                print(" - Package: \(package) -> \(versions)")
            }
            exit(1)
        }
        writeLockFile(packages, lock: lockFile)
        exit(0)
    }
case "update":
    let packages = update(package, lock: lockFile)
    if packages.count > 0 {
        if let conflicts = validateVersions(packages: packages) {
            print("Can not solve the version graph. The following conflicts were detected:")
            for (package, versions) in conflicts {
                print(" - Package: \(package) -> \(versions)")
            }
            exit(1)
        }
        writeLockFile(packages, lock: lockFile)
        exit(0)
    }
case "pin":
    if CommandLine.arguments.count == 3 {
        let packages = pinStatus(package, lock: lockFile, name: CommandLine.arguments[2], pinned: true)
        if packages.count > 0 {
            writeLockFile(packages, lock: lockFile)
        }
        exit(0)
    } else {
        print("Usage: atpm pin <package-name>")
    }
case "unpin":
    if CommandLine.arguments.count == 3 {
        let packages = pinStatus(package, lock: lockFile, name: CommandLine.arguments[2], pinned: false)
        if packages.count > 0 {
            writeLockFile(packages, lock: lockFile)
        }
        exit(0)
    } else {
        print("Usage: atpm pin <package-name>")
    }
case "override":
    if CommandLine.arguments.count == 4 {
        let packages = overrideURL(package, lock: lockFile, name: CommandLine.arguments[2], newURL: CommandLine.arguments[3])
        if packages.count > 0 {
            writeLockFile(packages, lock: lockFile)
        }
        exit(0)
    } else {
        print("Usage: atpm override <package-name> <overridden-url>")
    }
case "restore":
    if CommandLine.arguments.count == 3 {
        let packages = overrideURL(package, lock: lockFile, name: CommandLine.arguments[2], newURL: nil)
        if packages.count > 0 {
            writeLockFile(packages, lock: lockFile)
        }
        exit(0)
    } else {
        print("Usage: atpm restore <package-name>")
    }
default:
    help()
}

print("Nothing to do.")
exit(0)