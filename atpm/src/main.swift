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

let version = "0.1.0-dev"

import Foundation
import atpkg
import atpm_tools

let defaultBuildFile = "build.atpkg"
let defaultLockFile = "build.atlock"

func loadPackageFile() -> Package {
    do {
        return try Package(filepath: defaultBuildFile, overlay: [], focusOnTask: nil)
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

func info(package: Package, indent: Int = 4) -> Bool {
    for dep in package.externals {
        var out = ""
        for _ in 0..<indent {
            out += " "
        }
        out += "- \(dep.gitURL)"
        print(out)

        let subPackagePath = "external/\(dep.name)/build.atpkg"
        do {
            let subPackage = try Package(filepath: subPackagePath, overlay: [], focusOnTask: nil)
            info(subPackage, indent: indent + 4)
        } catch {
            out = ""
            for _ in 0..<indent {
                out += " "
            }
            out += "-> Could not load Package file: \(error)"
            print(out)
        }
    }
    return true
}

func fetch(package: Package, lock: LockFile?) -> [ExternalDependency] {
    var packages = [ExternalDependency]()

    for pkg in package.externals {
        print("Fetching external dependency \(pkg.name)...")
        do {
            try fetchDependency(pkg, lock: lock?[pkg.gitURL])

            symlink("..", "external/\(pkg.name)/external")
            let subPackagePath = "external/\(pkg.name)/build.atpkg"
            do {
                let p = try Package(filepath: subPackagePath, overlay: [], focusOnTask: nil)
                packages.append(pkg)
                packages += fetch(p, lock: lock)
            } catch {
                print("Unable to load build file '\(subPackagePath)': \(error)")
                continue
            }
        } catch {
            print("ERROR: Could not fetch \(pkg.name): \(error)")
            exit(1)
        }
    }
    return packages
}

func update(package: Package, lock: LockFile?) -> [ExternalDependency] {
    var packages = [ExternalDependency]()

    for pkg in package.externals {
        print("Updating external dependency \(pkg.name)...")
        do {
            try updateDependency(pkg, lock: lock?[pkg.gitURL])
            symlink("..", "external/\(pkg.name)/external")
            let subPackagePath = "external/\(pkg.name)/build.atpkg"
            do {
                let p = try Package(filepath: subPackagePath, overlay: [], focusOnTask: nil)
                packages.append(pkg)
                packages += update(p, lock: lock)
            } catch {
                print("Unable to load build file '\(subPackagePath)': \(error)")
            }
        } catch {
            print("ERROR: Could not fetch \(pkg.name): \(error)")
            return packages
        }
    }
    return packages
}

func pinStatus(package: Package, lock: LockFile?, name: String, pinned: Bool) -> [ExternalDependency] {
    var packages = [ExternalDependency]()
    let lockFile: LockFile = lock ?? LockFile()

    for pkg in package.externals {
        let subPackagePath = "external/\(pkg.name)/build.atpkg"
        do {
            let p = try Package(filepath: subPackagePath, overlay: [], focusOnTask: nil)
            packages.append(pkg)
            packages += pinStatus(p, lock: lock, name: name, pinned: pinned)
        } catch {
            print("Unable to load build file '\(subPackagePath)': \(error)")
        }
    }
    for pkg in packages {
        if pkg.name == name {
            guard let usedCommitID = getCurrentCommitID(pkg) else {
                print("ERROR: Corrupt git repository for package \(pkg.name)")
                exit(1)
            }

            let lockedPackage = lockFile[pkg.gitURL]
            if pinned {
                lockFile[pkg.gitURL] = LockedPackage(url: pkg.gitURL, usedCommitID: usedCommitID, pinnedCommitID: usedCommitID, overrideURL: lockedPackage?.overrideURL)
            } else {
                lockFile[pkg.gitURL] = LockedPackage(url: pkg.gitURL, usedCommitID: usedCommitID, overrideURL: lockedPackage?.overrideURL)
            }
        }
    }

    return packages
}

func overrideURL(package: Package, lock: LockFile?, name: String, newURL: String?) -> [ExternalDependency] {
    var packages = [ExternalDependency]()
    let lockFile: LockFile = lock ?? LockFile()

    for pkg in package.externals {
        let subPackagePath = "external/\(pkg.name)/build.atpkg"
        do {
            let p = try Package(filepath: subPackagePath, overlay: [], focusOnTask: nil)
            packages.append(pkg)
            packages += overrideURL(p, lock: lock, name: name, newURL: newURL)
        } catch {
            print("Unable to load build file '\(subPackagePath)': \(error)")
        }
    }
    for pkg in packages {
        if pkg.name == name {
            guard let usedCommitID = getCurrentCommitID(pkg) else {
                print("ERROR: Corrupt git repository for package \(pkg.name)")
                exit(1)
            }

            let lockedPackage = lockFile[pkg.gitURL]
            lockFile[pkg.gitURL] = LockedPackage(url: pkg.gitURL, usedCommitID: usedCommitID, pinnedCommitID: lockedPackage?.pinnedCommitID, overrideURL: newURL)
        }
    }

    return packages
}

func writeLockFile(packages: [ExternalDependency], lock: LockFile?) {
    let lockFile: LockFile = lock ?? LockFile()

    var newPackages = [LockedPackage]()

    let lockPkgs = lockFile.packages
    for pkg in packages {
        guard let usedCommitID = getCurrentCommitID(pkg) else {
            print("ERROR: Corrupt git repository for package \(pkg.name)")
            exit(1)
        }

        var found = false
        for lockedPkg in lockPkgs {
            if lockedPkg.url == pkg.gitURL {
                newPackages.append(LockedPackage(url: pkg.gitURL, usedCommitID: usedCommitID, pinnedCommitID:lockedPkg.pinnedCommitID, overrideURL:lockedPkg.overrideURL))
                found = true
                break
            }
        }
        if !found {
            newPackages.append(LockedPackage(url: pkg.gitURL, usedCommitID:usedCommitID))
        }
    }
    lockFile.packages = newPackages
    let string = lockFile.serialize()
    do {
        try string.writeToFile(defaultLockFile, atomically: true, encoding: NSUTF8StringEncoding)
    } catch {
        print("ERROR: Could not write lock file \(defaultLockFile)")
    }
}

func help() {
    print("atpm - Anarchy Tools Package Manager \(version)")
    print("https://github.com/AnarchyTools")
    print("© 2016 Anarchy Tools Contributors.")
    print("")
    print("Usage:")
    print("  atpm [info|fetch|update|pin|unpin|override]")
}

//usage message
if Process.arguments.contains("--help") {
    help()
    exit(0)
}

// MARK: - Argument handling

let package = loadPackageFile()
let lockFile = loadLockFile()

guard Process.arguments.count > 1 else {
    help()
    exit(1)
}

switch Process.arguments[1] {
case "info":
    print("Dependencies:")
    if info(package) {
        exit(0)
    }
case "fetch":
    let packages = fetch(package, lock: lockFile)
    if packages.count > 0 {
        if let conflicts = validateVersions(packages) {
            print("Can not solve the version graph. The following conflicts were detected:")
            for (package, versions) in conflicts {
                print(" - Package: \(package.name) -> \(versions)")
            }
            exit(1)
        }
        writeLockFile(packages, lock: lockFile)
        exit(0)
    }
case "update":
    let packages = update(package, lock: lockFile)
    if packages.count > 0 {
        if let conflicts = validateVersions(packages) {
            print("Can not solve the version graph. The following conflicts were detected:")
            for (package, versions) in conflicts {
                print(" - Package: \(package.name) -> \(versions)")
            }
            exit(1)
        }
        writeLockFile(packages, lock: lockFile)
        exit(0)
    }
case "pin":
    if Process.arguments.count == 3 {
        let packages = pinStatus(package, lock: lockFile, name: Process.arguments[2], pinned: true)
        if packages.count > 0 {
            writeLockFile(packages, lock: lockFile)
        }
        exit(0)
    } else {
        print("Usage: atpm pin <package-name>")
    }
case "unpin":
    if Process.arguments.count == 3 {
        let packages = pinStatus(package, lock: lockFile, name: Process.arguments[2], pinned: false)
        if packages.count > 0 {
            writeLockFile(packages, lock: lockFile)
        }
        exit(0)
    } else {
        print("Usage: atpm pin <package-name>")
    }
case "override":
    if Process.arguments.count == 4 {
        let packages = overrideURL(package, lock: lockFile, name: Process.arguments[2], newURL: Process.arguments[3])
        if packages.count > 0 {
            writeLockFile(packages, lock: lockFile)
        }
        exit(0)
    } else if Process.arguments.count == 3 {
        let packages = overrideURL(package, lock: lockFile, name: Process.arguments[2], newURL: nil)
        if packages.count > 0 {
            writeLockFile(packages, lock: lockFile)
        }
        exit(0)
    } else {
        print("Usage: atpm override <package-name> [<overridden-url>]")
    }
default:
    help()
}

exit(1)