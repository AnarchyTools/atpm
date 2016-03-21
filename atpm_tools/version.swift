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

extension Int {
    init(_ character: Character) {
        let s = String(character)
        self = Int(s.unicodeScalars.first!.value)
    }
}

public class Version {
    public var major: Int
    public var minor: Int
    public var patch: Int
    public var ext: String
    
    public var outputMinor: Bool = false
    public var outputPatch: Bool = false
    
    private enum ParserState {
    case Major
    case Minor
    case Patch
    case Ext
    case Invalid
    case Finished
    }
    
    public init(string: String) {
        var gen = string.characters.makeIterator()
        
        self.major = 0
        self.minor = 0
        self.patch = 0
        self.ext = ""
        
        var state:ParserState = .Major
        while let c = gen.next() {
            switch state {
            case .Major:
                state = self.parseMajor(c)
            case .Minor:
                self.outputMinor = true
                state = self.parseMinor(c)
            case .Patch:
                self.outputPatch = true
                state = self.parsePatch(c)
            case .Ext:
                state = self.parseExt(c)
            case .Invalid:
                break
            case .Finished:
                break
            }
        }
    }
    
    public init(major: Int, minor: Int, patch: Int = 0, ext: String = "") {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.ext = ext
    }
    
    @inline(__always)
    private func parseMajor(c: Character) -> ParserState {
        switch c {
        case "v", "V":
            break
        case "0"..."9":
            self.major = self.major * 10 + (Int(c) - 48)
        case ".":
            return .Minor
        default:
            return .Invalid
        }
        return .Major
    }
    
    @inline(__always)
    private func parseMinor(c: Character) -> ParserState  {
        switch c {
        case "0"..."9":
            self.minor = self.minor * 10 + (Int(c) - 48)
        case ".":
            return .Patch
        case "\n":
            return .Finished
        default:
            return self.parseExt(c)
        }
        return .Minor
    }

    @inline(__always)
    private func parsePatch(c: Character) -> ParserState  {
        switch c {
        case "0"..."9":
            self.patch = self.patch * 10 + (Int(c) - 48)
        case "\n":
            return .Finished
        default:
            return self.parseExt(c)
        }
        return .Patch
    }

    @inline(__always)
    private func parseExt(c: Character) -> ParserState  {
        if c == "\n" {
            return .Finished
        }
        self.ext.append(c)
        return .Ext
    }
}

public func < (lhs: Version, rhs: Version) -> Bool {
    if lhs.major < rhs.major {
        return true
    } else if lhs.major == rhs.major {
        if lhs.minor < rhs.minor {
            return true
        } else if lhs.minor == rhs.minor {
            if lhs.patch < rhs.patch {
                return true
            } else if lhs.patch == rhs.patch {
                if rhs.ext.characters.count == 0 && lhs.ext.characters.count > 0 {
                    return true
                } else if lhs.ext == rhs.ext {
                    return false
                } else {
                    return [lhs.ext, rhs.ext].sorted()[0] == lhs.ext
                }
            }
        }
    }
    return false
}

public func <= (lhs: Version, rhs: Version) -> Bool {
    return lhs < rhs || lhs == rhs
}

public func > (lhs: Version, rhs: Version) -> Bool {
    if lhs.major > rhs.major {
        return true
    } else if lhs.major == rhs.major {
        if lhs.minor > rhs.minor {
            return true
        } else if lhs.minor == rhs.minor {
            if lhs.patch > rhs.patch {
                return true
            } else if lhs.patch == rhs.patch {
                if lhs.ext.characters.count == 0 && rhs.ext.characters.count > 0 {
                    return true
                } else if lhs.ext == rhs.ext {
                    return false
                } else {
                    return [lhs.ext, rhs.ext].sorted()[0] == rhs.ext
                }
            }
        }
    }
    return false
}

public func >= (lhs: Version, rhs: Version) -> Bool {
    return lhs > rhs || lhs == rhs
}

public func == (lhs: Version, rhs: Version) -> Bool {
    return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch && lhs.ext == rhs.ext
}

extension Version: Equatable {
}

extension Version: Hashable {
    public var hashValue: Int {
        return self.major * 1000000 + self.minor * 1000 + self.patch + self.ext.hashValue * 1000000000
    }
}

extension Version: CustomStringConvertible {
    public var description: String {
        var v = "\(self.major)"
        if self.outputMinor {
            v += ".\(self.minor)"
            if self.outputPatch {
                v += ".\(self.patch)"
            }
        }
        if self.ext.characters.count > 0 {
            v += "\(self.ext)"
        }
        return v
    }
}

