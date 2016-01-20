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

#if os(Linux)
//we need to get exit somehow
//https://bugs.swift.org/browse/SR-567
import Glibc
#endif

let defaultBuildFile = "build.atpkg"

func loadPackageFile() -> Package {

    //build overlays
    var overlays : [String] = []
    for (i, x) in Process.arguments.enumerate() {
        if x == "--overlay" {
            let overlay = Process.arguments[i+1]
            overlays.append(overlay)
        }
    }
    guard let package = Package(filepath: defaultBuildFile, overlay: overlays) else {
        print("Unable to load build file: \(defaultBuildFile)")
        exit(1)
    }

    return package
}

func updateDependency(pkg: ExternalDependency) -> Bool {
    let fm = NSFileManager.defaultManager()
    if !fm.fileExistsAtPath("external/\(pkg.name)") {
        return false
    }

    switch pkg.version {
    case .Branch(let branch):
        return system("cd external/\(pkg.name) && git checkout \(branch)") == 0
    case .Commit(let commitID):
        return system("cd external/\(pkg.name) && git checkout \(commitID)") == 0
    case .Version(let major, let minor):
        // fetch all tags
        print("Not implemented yet")
        return false
    }
}

func fetchDependency(pkg: ExternalDependency) -> Bool {
    let fm = NSFileManager.defaultManager()
    if fm.fileExistsAtPath("external/\(pkg.name)") {
        print("Already downloaded")
        return true
    }
    
    do {
        try fm.createDirectoryAtPath("external", withIntermediateDirectories: true, attributes: nil)
    } catch {
        return false
    }
    
    let cloneResult = system("git clone \(pkg.gitURL) external/\(pkg.name)")
    if cloneResult != 0 {
        return false
    }
    
    return updateDependency(pkg)
}

func help() {
    print("atpm - Anarchy Tools Package Manager \(version)")
    print("https://github.com/AnarchyTools")
    print("© 2016 Anarchy Tools Contributors.")
    print("")
    print("Usage:")
    print("  atpm [info|fetch|update|add|install|uninstall]")
}

//usage message
if Process.arguments.contains("--help") {
    help()
    exit(0)
}

let package = loadPackageFile()

switch Process.arguments[1] {
case "info":
    print("Dependencies:")
    for dep in package.externals {
        print("    \(dep.gitURL)")
    }
    exit(0)
case "fetch":
    for pkg in package.externals {
        print("Fetching external dependency \(pkg.name)...")
        if fetchDependency(pkg) != true {
            print("ERROR: Could not fetch \(pkg.name)")
            exit(1)
        }
    }
    exit(0)
case "update":
    for pkg in package.externals {
        print("Updating external dependency \(pkg.name)...")
        if updateDependency(pkg) != true {
            print("ERROR: Could not fetch \(pkg.name)")
            exit(1)
        }
    }
    exit(0)
case "add":
    print("not implemented")
case "install":
    print("not implemented")
case "uninstall":
    print("not implemented")
default:
    help()
}

exit(1)