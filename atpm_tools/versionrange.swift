import Foundation

public class VersionRange {
	public var min: Version?
	public var minInclusive: Bool?
	public var max: Version?
	public var maxInclusive: Bool?

	public enum Error: ErrorType {
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
            let tmp = Version(string: versionString.substringFromIndex(versionString.startIndex.advancedBy(2)))
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
            let tmp = Version(string: versionString.substringFromIndex(versionString.startIndex.advancedBy(1)))
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
            let tmp = Version(string: versionString.substringFromIndex(versionString.startIndex.advancedBy(2)))
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
            let tmp = Version(string: versionString.substringFromIndex(versionString.startIndex.advancedBy(1)))
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
            let tmp = Version(string: versionString.substringFromIndex(versionString.startIndex.advancedBy(2)))
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