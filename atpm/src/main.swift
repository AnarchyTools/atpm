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

#if os(Linux)
//we need to get exit somehow
//https://bugs.swift.org/browse/SR-567
import Glibc
#endif

let defaultBuildFile = "build.atpkg"

func loadPackageFile() -> Package {
    guard let package = Package(filepath: defaultBuildFile, overlay: []) else {
        print("Unable to load build file: \(defaultBuildFile)")
        exit(1)
    }

    return package
}

func fetchVersions(pkg: ExternalDependency) -> [Version] {
    let fp = popen("cd external/\(pkg.name) && git tag -l *.*.* -l *.* -l v*.*.* -l v*.*", "r")
    guard fp != nil else {
        return []
    }
    defer {
        fclose(fp)
    }
    
    var versions = [Version]()
    var buffer = [CChar](count: 255, repeatedValue: 0)
    while feof(fp) == 0 {
        if fgets(&buffer, 255, fp) == nil {
            break
        }
        if let versionString = String.fromCString(buffer) {
            versions.append(Version(string: versionString))
        }
    }
    return versions
}

func updateDependency(pkg: ExternalDependency) -> Bool {
    let fm = NSFileManager.defaultManager()
    if !fm.fileExistsAtPath("external/\(pkg.name)") {
        return false
    }

    if system("cd external/\(pkg.name) && git fetch origin") != 0 {
        return false
    }
    
    switch pkg.version {
    case .Branch(let branch):
        return system("cd external/\(pkg.name) && git checkout \(branch) && git pull origin") == 0
    case .Tag(let tag):
        return system("cd external/\(pkg.name) && git checkout \(tag)") == 0
    case .Commit(let commitID):
        return system("cd external/\(pkg.name) && git checkout \(commitID)") == 0
    case .Version(let version):
        var min: Version? = nil
        var max: Version? = nil
        
        var minEquals = true
        var maxEquals = true
        for ver in version {
            if ver.hasPrefix(">=") {
                min = Version(string: ver.substringFromIndex(ver.startIndex.advancedBy(2)))
            } else if ver.hasPrefix(">") {
                min = Version(string: ver.substringFromIndex(ver.startIndex.advancedBy(1)))
                minEquals = false
            } else if ver.hasPrefix("<=") {
                max = Version(string: ver.substringFromIndex(ver.startIndex.advancedBy(2)))
            } else if ver.hasPrefix("<") {
                max = Version(string: ver.substringFromIndex(ver.startIndex.advancedBy(1)))
                maxEquals = false
            } else if ver.hasPrefix("==") {
                max = Version(string: ver.substringFromIndex(ver.startIndex.advancedBy(2)))
                min = max
            } else {
                max = Version(string: ver)
                min = max
            }
        }
        var versions = fetchVersions(pkg)
        
        do {
            versions = try versions.filter { version throws -> Bool in
                var valid = true
                if let min = min {
                    if minEquals {
                        valid = (version >= min)
                    } else {
                        valid = (version > min)
                    }
                }
                
                if !valid {
                    return false
                }

                if let max = max {
                    if maxEquals {
                        valid = (version <= max)
                    } else {
                        valid = (version < max)
                    }
                }
                
                return valid
            }

            versions.sortInPlace { (v1, v2) -> Bool in
                return v1 < v2
            }
            
            if versions.count > 0 {
                print("Valid versions: \(versions), using \(versions.last!)")
                return system("cd external/\(pkg.name) && git checkout \(versions.last!)") == 0
            } else {
                print("No valid versions for \(pkg.name)!")
            }
        } catch {
            return false
        }
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
    
    let cloneResult = system("git clone --recurse-submodules \(pkg.gitURL) external/\(pkg.name)")
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