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
import Foundation
import atpkg

enum LockFileError: ErrorProtocol {
    case NonVectorImport
    case ParserFailed
    case NonLockFile
}

final public class LockedPackage {
    public let url: String
    private(set) public var usedCommitID: String
    private(set) public var pinnedCommitID: String? = nil
    private(set) public var overrideURL:String?     = nil

    public enum Option: String {
        case URL = "url"
        case UsedCommit = "used-commit"
        case PinCommit = "pin-commit"
        case OverrideURL = "override-url"

        public static var allOptions: [Option] {
            return [
                    URL,
                    UsedCommit,
                    PinCommit,
                    OverrideURL
            ]
        }
    }

    init(url: String, usedCommitID: String, pinnedCommitID: String? = nil, overrideURL: String? = nil) {
        self.url = url
        self.usedCommitID = usedCommitID
        self.pinnedCommitID = pinnedCommitID
        self.overrideURL = overrideURL
    }

    init?(package: ParseValue) {
        guard let kvp = package.map else { return nil }

        guard let url = kvp[Option.URL.rawValue]?.string else {
            fatalError("No URL for locked package; did you forget to specify it?")
        }
        guard let usedCommitID = kvp[Option.UsedCommit.rawValue]?.string else {
            fatalError("No commit ID for locked package; did you forget to specify it?")
        }

        self.url = url
        self.usedCommitID = usedCommitID

        if let pinnedCommitID = kvp[Option.PinCommit.rawValue]?.string {
            self.usedCommitID = pinnedCommitID
            self.pinnedCommitID = pinnedCommitID
        }

        if let overrideURL = kvp[Option.OverrideURL.rawValue]?.string {
            self.overrideURL = overrideURL
        }
    }

    func serialize() -> [String] {
        var result = [String]()

        result.append("{")
        result.append("  :\(Option.URL.rawValue) \"\(self.url)\"")
        result.append("  :\(Option.UsedCommit.rawValue) \"\(self.usedCommitID)\"")
        
        if let pinnedCommitID = self.pinnedCommitID {
            result.append("  :\(Option.PinCommit.rawValue) \"\(pinnedCommitID)\"")
        }

        if let overrideURL = self.overrideURL {
            result.append("  :\(Option.OverrideURL.rawValue) \"\(overrideURL)\"")
        }
        result.append("}")
        return result
    }    
}

public func == (lhs: LockedPackage, rhs: LockedPackage) -> Bool {
    return lhs.url == rhs.url
}

extension LockedPackage: Hashable {
     public var hashValue: Int {
        return self.url.hashValue
     }
}

final public class LockFile {
    public enum Key: String {
        case LockFileTypeName = "lock-file"
        case Packages = "packages"

        static var allKeys: [Key] {
            return [
                    LockFileTypeName,
                    Packages,
            ]
        }
    }

    public var packages: [LockedPackage] = []

    public convenience init(filepath: String) throws {
        guard let parser = Parser(filepath: filepath) else { throw LockFileError.ParserFailed }
        let result = try parser.parse()
        try self.init(type: result)
    }

    public init(type: ParseType) throws {
        //warn on unknown keys
        for (k,_) in type.properties {
            if !Key.allKeys.map({$0.rawValue}).contains(k) {
                print("Warning: unknown lock-file key \(k)")
            }
        }

        if type.name != "lock-file" { throw LockFileError.NonLockFile }

        if let parsedPackages = type.properties[Key.Packages.rawValue] {
            guard let packages = parsedPackages.vector else {
                throw LockFileError.NonVectorImport
            }
            for package in packages {
                if let lockedPackage = LockedPackage(package: package) {
                    self.packages.append(lockedPackage)
                }
            }
        }
    }

    public init() {
    }

    public subscript(url: String) -> LockedPackage? {
        get {
            for lock in self.packages {
                if lock.url == url {
                    return lock
                }
            }
            return nil
        }

        set(newValue) {
            var index: Int? = nil
            for lock in self.packages {
                if lock.url == url {
                    index = self.packages.index(of:lock)
                    break
                }
            }

            if let v = newValue {
                if let index = index {
                    self.packages[index] = v
                } else {
                    self.packages.append(v)
                }
            } else {
                if let index = index {
                    self.packages.remove(at:index)
                }
            }
        }
    }

    public func serialize() -> String {
        var result = ";; Anarchy Tools Package Manager lock file\n;;\n"

        result += ";; If you want to pin a package to a git commit add a ':pin-commit'\n"
        result += ";; line to that package definition. This will override all version\n"
        result += ";; information the build files specify.\n;;\n"

        result += ";; You may override the repository URL for a package by specifying\n"
        result += ";; it in an ':override-url' line. This is very handy if you develop\n"
        result += ";; the dependency in parallel to the package that uses it\n\n"

        result += "(\(Key.LockFileTypeName.rawValue)\n"
        result += "  :packages [\n"

        for pkg in self.packages {
            let serialized = pkg.serialize()
            for line in serialized {
                result += "    \(line)\n"
            }
        }

        result += "  ]\n"
        result += ")\n"

        return result
    }
}
