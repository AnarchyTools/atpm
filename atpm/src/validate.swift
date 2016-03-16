import Foundation
import atpkg
import atpm_tools

func ==(lhs:ExternalDependency.VersioningMethod, rhs: ExternalDependency.VersioningMethod) -> Bool {
	switch (lhs, rhs) {
	case (.Branch(let a), .Branch(let b)) where a == b: return true
	case (.Tag(let a),    .Tag(let b))    where a == b: return true
	case (.Commit(let a), .Commit(let b)) where a == b: return true
	case (.Version,       .Version): return true
	default: return false
	}
}

// This validates if the version graph of the package list can be solved
//
// Returns the Package list that can't be solved, the user has to specify an override
// in the lockfile to solve the conflict.
//
// Returns `nil` if everything was ok
func validateVersions(packages: [ExternalDependency]) -> [String:[ExternalDependency.VersioningMethod]]? {
	var grouped = [String:[ExternalDependency]]()
	for p in packages {
		if grouped[p.gitURL] == nil {
			grouped[p.gitURL] = [ExternalDependency]()
		}
		grouped[p.gitURL]!.append(p)
	}

	var failed = Dictionary<String, Array<ExternalDependency.VersioningMethod>>()

	for (_, deps) in grouped {
		var vMethod: ExternalDependency.VersioningMethod? = nil
		var versionRange: VersionRange? = nil

		for pkg in deps {
			// first loop sets the default
			if vMethod == nil {
				vMethod = pkg.version
				versionRange = VersionRange()
				continue
			}

			// this should not happen ever
			guard let vMethod = vMethod,
				  let versionRange = versionRange else {
				continue
			}

			// if this pkg has the same versioning scheme
			if vMethod == pkg.version {
				// check version
				if case .Version(let versions) = pkg.version {
					for v in versions {
						do {
							try versionRange.combine(v)
						} catch {
							// so we cannot combine the ranges -> failed
							if failed[pkg.name] == nil {
								failed[pkg.name] = []
								failed[pkg.name]!.append(vMethod)
							}
							failed[pkg.name]!.append(pkg.version)
						}
					}
				}
			} else {
				// different versioning schemes don't match by definition
				if failed[pkg.name] == nil {
					failed[pkg.name] = []
					failed[pkg.name]!.append(vMethod)
				}
				failed[pkg.name]!.append(pkg.version)
			}
    	}
	}

	if failed.count > 0 {
		return failed
	}
	return nil
}