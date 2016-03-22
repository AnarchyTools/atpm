import Foundation

//SR-138
#if os(Linux)
extension String {
    public func substring(with range: Range<String.Index>) -> String {
        var result = ""
        result.reserveCapacity(range.count)
        for idx in range {
            result.append(self.characters[idx])
        }
        return result
    }

    public func substring(to index: String.Index) -> String {
        return self.substring(with: self.startIndex..<index)
    }

    public func substring(from index: String.Index) -> String {
        return self.substring(with: index..<self.endIndex)
    }
}
#endif

public class VersionRange {
	public var min: Version?
	public var minInclusive: Bool?
	public var max: Version?
	public var maxInclusive: Bool?

	public enum Error: ErrorProtocol {
		case CombiningFailed
	}

	public init(versionString: String) {
		do {
			try self.combine(versionString)
		} catch {
			// first combine will never throw
		}
	}

	public init() {
	}

	public func combine(versionString: String) throws {
		if versionString.hasPrefix(">=") {
            let tmp = Version(string: versionString.substring(from: versionString.startIndex.advanced(by:2)))
			if self.min != nil {
				if (tmp == self.min! && self.minInclusive == false) || tmp < self.min! {
					return
				}
			}
			if self.max != nil {
				if tmp > self.max! || (self.maxInclusive == false && tmp == self.max!) {
					throw VersionRange.Error.CombiningFailed
				}
			}
			self.min = tmp
			self.minInclusive = true
        } else if versionString.hasPrefix(">") {
            let tmp = Version(string: versionString.substring(from: versionString.startIndex.advanced(by:1)))
			if self.min != nil {
				if tmp < self.min! {
					return
				}
			}
			if self.max != nil {
				if tmp >= self.max! {
					throw VersionRange.Error.CombiningFailed
				}
			}
			self.min = tmp
            self.minInclusive = false
        } else if versionString.hasPrefix("<=") {
            let tmp = Version(string: versionString.substring(from: versionString.startIndex.advanced(by:2)))
			if self.max != nil {
				if (tmp == self.max! && self.maxInclusive == false) || tmp > self.max! {
					return
				}
			}
			if self.min != nil {
				if tmp < self.min! || (self.minInclusive == false && tmp == self.min!) {
					throw VersionRange.Error.CombiningFailed
				}
			}
			self.max = tmp
            self.maxInclusive = true
        } else if versionString.hasPrefix("<") {
            let tmp = Version(string: versionString.substring(from: versionString.startIndex.advanced(by:1)))
			if self.max != nil {
				if tmp > self.max! {
					return
				}
			}
			if self.min != nil {
				if tmp <= self.min! {
					throw VersionRange.Error.CombiningFailed
				}
			}
			self.max = tmp
            self.maxInclusive = false
        } else if versionString.hasPrefix("==") {
            let tmp = Version(string: versionString.substring(from: versionString.startIndex.advanced(by:2)))
            if self.max != nil {
            	if tmp > self.max! {
					throw VersionRange.Error.CombiningFailed
            	}
            }
            if self.min != nil {
            	if tmp < self.min! {
            		throw VersionRange.Error.CombiningFailed
            	}
            }
            self.max = tmp
            self.min = max
            self.minInclusive = true
            self.maxInclusive = true
        } else {
            let tmp = Version(string: versionString)
            if self.max != nil {
            	if tmp > self.max! {
					throw VersionRange.Error.CombiningFailed
            	}
            }
            if self.min != nil {
            	if tmp < self.min! {
            		throw VersionRange.Error.CombiningFailed
            	}
            }
            self.max = tmp
            self.min = max
            self.minInclusive = true
            self.maxInclusive = true
        }
	}

	public func versionInRange(version: Version) -> Bool {
        var valid = true
        if let min = self.min {
            if self.minInclusive! {
                valid = (version >= min)
            } else {
                valid = (version > min)
            }
        }

        if !valid {
            return false
        }

        if let max = self.max {
            if self.maxInclusive! {
                valid = (version <= max)
            } else {
                valid = (version < max)
            }
        }

        return valid
	}
}

extension VersionRange: CustomStringConvertible {
	public var description: String {
		if let min = self.min, max = self.max where min == max {
			return "==\(min)"
		} else {
			var result = ""
			if let min = self.min {
				if self.minInclusive == true {
					result += ">=\(min)"
				} else {
					result += ">\(min)"
				}
			}
			if self.min != nil && self.max != nil {
				result += ", "
			}	
			if let max = self.max {
				if self.maxInclusive == true {
					result += "<=\(max)"
				} else {
					result += "<\(max)"
				}
			}
			return result
		}
	}
}