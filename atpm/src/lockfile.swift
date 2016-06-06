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

import atfoundation
import atpkg

enum LockFileError: ErrorProtocol {
    case NonVectorImport
    case ParserFailed
    case NonLockFile
}

public struct LockedPackage {
    public let url: URL
    var payloads: [LockedPayload]

    ///Gets a payload matching the key
    public func payloadMatching(key: String) -> LockedPayload? {
        if let payload = self.payloads.filter({$0.key == key}).first {
            return payload
        }    
        return nil
    }

    ///Gets or creates a payload matching the key
    public mutating func createPayloadMatching(key: String) -> LockedPayload {
        if let payload = self.payloadMatching(key: key) {
            return payload
        }
        let newPayload = LockedPayload(key: key)
        self.payloads.append(newPayload)
        return newPayload
    }

    public var gitPayload : LockedPayload {
        get {
            precondition(payloads.count == 1)
            precondition(payloads[0].key == "git")
            return payloads[0]  
        }
        set {
            precondition(newValue.key == "git")
            switch(payloads.count) {
                case 1:
                precondition(payloads[0].key == "git")
                payloads.removeFirst()
                payloads.append(newValue)
                case 0:
                payloads.append(newValue)
                default:
                fatalError("Not supported")
            }
        }

    }

    init(url: URL, payloads: [LockedPayload]) {
        self.url = url
        self.payloads = payloads
    }

    init(package: ParseValue) {
        guard let kvp = package.map else {
            fatalError("Non-map lock package")
        }
        guard let url = kvp[Option.URL.rawValue]?.string else {
            fatalError("No URL for package")
        }
        self.url = URL(string: url)

        guard let payloads = kvp[Option.Payloads.rawValue]?.vector else {
            fatalError("No payloads for package")
        }
        self.payloads = []
        for payload in payloads {
            let lockedPayload = LockedPayload(payload: payload)!
            self.payloads.append(lockedPayload)
        }
    }

    func serialize() -> [String] {
        var result = [String]()
        result.append("{")
        result.append("  :\(Option.URL.rawValue) \"\(self.url)\"")
        result.append("  :\(Option.Payloads.rawValue) [")
        for payload in payloads {
            result.append(contentsOf: payload.serialize())
        }
        result.append("  ]")
        result.append("}")
        return result
    }

    public enum Option: String {
        case URL = "url"
        case Payloads = "payloads"
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

public struct LockedPayload {
    public let key: String
    internal(set) public var usedCommitID: String?  = nil
    internal(set) public var pinnedCommitID: String? = nil
    internal(set) public var overrideURL:String?     = nil

    ///For manifest-based packages, the URL we chose inside the manifest
    internal(set) public var usedURL: String?        = nil
    ///For manifest-based packages, the channel we loaded
    internal(set) public var usedVersion: String?    = nil
    ///For manifest-based packages, the shasum of the tarball
    internal(set) public var shaSum: String?         = nil

    public enum Option: String {
        case Key = "key"
        case UsedCommit = "used-commit"
        case PinCommit = "pin-commit"
        case OverrideURL = "override-url"
        case UsedURL = "used-url"
        case UsedVersion = "used-version"
        case ShaSum = "sha-sum"


        public static var allOptions: [Option] {
            return [
                    Key,
                    UsedCommit,
                    PinCommit,
                    OverrideURL,
                    UsedURL,
                    UsedVersion,
                    ShaSum
            ]
        }
    }

    init(key: String) {
        self.key = key
    }

    init?(payload: ParseValue) {


        guard let kvp = payload.map else { return nil }

        guard let key = kvp[Option.Key.rawValue]?.string else {
            fatalError("No key for locked package")
        }
        self.key = key


        if let usedCommitID = kvp[Option.UsedCommit.rawValue]?.string {
            self.usedCommitID = usedCommitID
        }


        if let pinnedCommitID = kvp[Option.PinCommit.rawValue]?.string {
            self.usedCommitID = pinnedCommitID
            self.pinnedCommitID = pinnedCommitID
        }

        if let overrideURL = kvp[Option.OverrideURL.rawValue]?.string {
            self.overrideURL = overrideURL
        }

        if let usedURL = kvp[Option.UsedURL.rawValue]?.string {
            self.usedURL = usedURL
        }

        if let usedVersion = kvp[Option.UsedVersion.rawValue]?.string {
            self.usedVersion = usedVersion
        }

        if let shaSum = kvp[Option.ShaSum.rawValue]?.string {
            self.shaSum = shaSum
        }

    }

    func serialize() -> [String] {
        var result = [String]()

        result.append("{")
        result.append("  :\(Option.Key.rawValue) \"\(self.key)\"")

        if let usedCommitID = self.usedCommitID {
            result.append("  :\(Option.UsedCommit.rawValue) \"\(usedCommitID)\"")
        }

        if let pinnedCommitID = self.pinnedCommitID {
            result.append("  :\(Option.PinCommit.rawValue) \"\(pinnedCommitID)\"")
        }

        if let overrideURL = self.overrideURL {
            result.append("  :\(Option.OverrideURL.rawValue) \"\(overrideURL)\"")
        }

        if let usedURL = self.usedURL {
            result.append("  :\(Option.UsedURL.rawValue) \"\(usedURL)\"")
        }

        if let usedVersion = self.usedVersion {
            result.append("  :\(Option.UsedVersion.rawValue) \"\(usedVersion)\"")
        }
        if let shaSum = self.shaSum {
            result.append("  :\(Option.ShaSum.rawValue) \"\(shaSum)\"")
        }

        result.append("}")
        return result
    }
}

public func == (lhs: LockedPayload, rhs: LockedPayload) -> Bool {
    return lhs.key == rhs.key
}

extension LockedPayload: Hashable {
     public var hashValue: Int {
        return self.key.hashValue
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

    public convenience init(filepath: Path) throws {
        guard let parser = try Parser(filepath: filepath) else { throw LockFileError.ParserFailed }
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
                let lockedPackage = LockedPackage(package: package)
                self.packages.append(lockedPackage)
            }
        }
    }

    public init() {
    }

    public subscript(url: URL) -> LockedPackage? {
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
