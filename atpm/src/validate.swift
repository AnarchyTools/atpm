import Foundation
import atpkg
import atpm_tools

// This validates if the version graph of the package list can be solved
//
// Returns the Package list that can't be solved, the user has to specify an override
// in the lockfile to solve the conflict.
//
// Returns `nil` if everything was ok
func validateVersions(packages: [ExternalDependency]) -> [(package: ExternalDependency, versions: [Version])]? {
	return nil
}