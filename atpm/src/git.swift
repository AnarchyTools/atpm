import Foundation
import atpkg
import atpm_tools

private func logAndExecute(command: String) -> Int32 {
    // print("Executing: \(command)")
    let exitCode = system(command)
    // print("Exit code: \(exitCode)")
    return exitCode
}

// Fetch versions (git-tags) from a checked out repo
//
// This only matches Tags like the templates below:
// - *.*.*
// - *.*
// - v*.*.*
// - v*.*
func fetchVersions(pkg: ExternalDependency) -> [Version] {
    let fp = popen("cd 'external/\(pkg.name)' && git tag -l *.*.* -l *.* -l v*.*.* -l v*.*", "r")
    guard fp != nil else {
        return []
    }
    defer {
        fclose(fp)
    }

    var versions = [Version]()
    var buffer = [CChar](repeating: 0, count: 255)
    while feof(fp) == 0 {
        if fgets(&buffer, 255, fp) == nil {
            break
        }
        if let versionString = String(validatingUTF8: buffer) {
            versions.append(Version(string: versionString))
        }
    }
    return versions
}

// Update an already checked out repository
//
// Returns `false` if repo does not exist or if a `git fetch origin` fails
func updateDependency(pkg: ExternalDependency, lock: LockedPackage?, firstTime: Bool = false) throws {
    let fm = NSFileManager.defaultManager()
    if !fm.fileExistsAtPath("external/\(pkg.name)") {
        throw PMError.MissingPackageCheckout
    }

    let fetchResult = logAndExecute("cd 'external/\(pkg.name)' && git fetch origin")
    if fetchResult != 0 {
        throw PMError.GitError(exitCode: fetchResult)
    }

    // If we are pinned only checkout that commit
    if let lock = lock where lock.pinnedCommitID != nil {
        print("Package \(pkg.name) is pinned to \(lock.pinnedCommitID!)")
        let pullResult = logAndExecute("cd 'external/\(pkg.name)' && git checkout '\(lock.pinnedCommitID!)'")
        if pullResult != 0 {
            throw PMError.GitError(exitCode: pullResult)
        }
        return
    }

    // on first time checkout only pull the commit that has been logged in the lockfile
    if let lock = lock where firstTime == true {
        print("Fetching commit as defined in lock file for \(pkg.name): \(lock.usedCommitID)")
        let pullResult = logAndExecute("cd 'external/\(pkg.name)' && git checkout '\(lock.usedCommitID)'")
        if pullResult != 0 {
            throw PMError.GitError(exitCode: pullResult)
        }
        return        
    }

    switch pkg.version {
    case .Branch(let branch):
        let pullResult = logAndExecute("cd 'external/\(pkg.name)' && git checkout '\(branch)' && git pull origin")
        if pullResult != 0 {
            throw PMError.GitError(exitCode: pullResult)
        }
    case .Tag(let tag):
        let pullResult = logAndExecute("cd 'external/\(pkg.name)' && git checkout '\(tag)'")
        if pullResult != 0 {
            throw PMError.GitError(exitCode: pullResult)
        }
    case .Commit(let commitID):
        let pullResult = logAndExecute("cd 'external/\(pkg.name)' && git checkout '\(commitID)'")
        if pullResult != 0 {
            throw PMError.GitError(exitCode: pullResult)
        }
    case .Version(let version):

        let versionRange = VersionRange()
        for ver in version {
            try versionRange.combine(ver)
        }
        var versions = fetchVersions(pkg)

        do {
            versions = try versions.filter { version throws -> Bool in
                return versionRange.versionInRange(version)
            }

            versions.sort(isOrderedBefore: { (v1, v2) -> Bool in
                return v1 < v2
            })

            if versions.count > 0 {
                print("Valid versions: \(versions), using \(versions.last!)")
                let pullResult = logAndExecute("cd 'external/\(pkg.name)' && git checkout '\(versions.last!)'")
                if pullResult != 0 {
                    throw PMError.GitError(exitCode: pullResult)
                }
            } else {
                print("No valid versions for \(pkg.name)!")
            }
        } catch PMError.GitError(let exitCode) {
            throw PMError.GitError(exitCode: exitCode)
        } catch {
            throw PMError.InvalidVersion
        }
    }
}

// Checkout a git repository and all its submodules
//
// This only checks out the default branch and calls updateDependency() for
// fetching the correct branch/tag
func fetchDependency(pkg: ExternalDependency, lock: LockedPackage?) throws {
    let fm = NSFileManager.defaultManager()
    if fm.fileExistsAtPath("external/\(pkg.name)") {
        print("Already downloaded")
        return
    }

    if !fm.fileExistsAtPath("external") {
        try fm.createDirectoryAtPath("external", withIntermediateDirectories: false, attributes: nil)
    }

    // If the url has been overridden checkout that repo instead
    if let lock = lock where lock.overrideURL != nil {
        print("Package \(pkg.name) repo URL overridden: \(lock.overrideURL!)")
        let cloneResult = logAndExecute("git clone --recurse-submodules '\(lock.overrideURL!)' 'external/\(pkg.name)'")
        if cloneResult != 0 {
            throw PMError.GitError(exitCode: cloneResult)
        }
        return
    }

    let cloneResult = logAndExecute("git clone --recurse-submodules '\(pkg.gitURL)' 'external/\(pkg.name)'")
    if cloneResult != 0 {
        throw PMError.GitError(exitCode: cloneResult)
    }

    try updateDependency(pkg, lock: lock, firstTime: true)
}

func getCurrentCommitID(pkg: ExternalDependency) -> String? {
    let fm = NSFileManager.defaultManager()
    if !fm.fileExistsAtPath("external/\(pkg.name)") {
        return nil
    }

    let fp = popen("cd 'external/\(pkg.name)' && git rev-parse HEAD", "r")
    guard fp != nil else {
        return nil
    }
    defer {
        fclose(fp)
    }

    var buffer = [CChar](repeating: 0, count: 255)
    while feof(fp) == 0 {
        if fgets(&buffer, 255, fp) == nil {
            break
        }
        if let commitID = String(validatingUTF8: buffer) {
            return commitID.substringToIndex(commitID.startIndex.advanced(by:commitID.characters.count - 1))
        }
    }
    return nil
}