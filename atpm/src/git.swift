import atfoundation
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
func fetchVersions(_ pkg: ExternalDependency) -> [Version] {
    let fp = popen("cd 'external/\(pkg.name!)' && git tag -l '*.*.*' -l '*.*' -l 'v*.*.*' -l 'v*.*'", "r")
    guard fp != nil else {
        return []
    }
    defer {
        pclose(fp)
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
func updateGitDependency(_ pkg: ExternalDependency, lock: LockedPackage?, firstTime: Bool = false) throws {
    if !FS.fileExists(path: Path("external/\(pkg.name!)")) {
        throw PMError.MissingPackageCheckout
    }

    let fetchResult = logAndExecute(command: "cd 'external/\(pkg.name!)' && git fetch --tags origin")
    if fetchResult != 0 {
        throw PMError.GitError(exitCode: fetchResult)
    }

    // If we are pinned only checkout that commit
    if let lock = lock where lock.gitPayload.pinned == true {
        print("Package \(pkg.name!) is pinned to \(lock.gitPayload.usedCommitID!)")
        let pullResult = logAndExecute(command: "cd 'external/\(pkg.name!)' && git checkout '\(lock.gitPayload.usedCommitID!)'")
        if pullResult != 0 {
            throw PMError.GitError(exitCode: pullResult)
        }
        return
    }

    // on first time checkout only pull the commit that has been logged in the lockfile
    if let lock = lock where firstTime == true {
        print("Fetching commit as defined in lock file for \(pkg.name!): \(lock.gitPayload.usedCommitID!)")
        let pullResult = logAndExecute(command: "cd 'external/\(pkg.name!)' && git checkout '\(lock.gitPayload.usedCommitID!)'")
        if pullResult != 0 {
            throw PMError.GitError(exitCode: pullResult)
        }
        return
    }

    switch pkg.version {
    case .Branch(let branch):
        let pullResult = logAndExecute(command: "cd 'external/\(pkg.name!)' && git checkout '\(branch)' && git pull origin")
        if pullResult != 0 {
            throw PMError.GitError(exitCode: pullResult)
        }
    case .Tag(let tag):
        let pullResult = logAndExecute(command: "cd 'external/\(pkg.name!)' && git checkout '\(tag)'")
        if pullResult != 0 {
            throw PMError.GitError(exitCode: pullResult)
        }
    case .Commit(let commitID):
        let pullResult = logAndExecute(command: "cd 'external/\(pkg.name!)' && git checkout '\(commitID)'")
        if pullResult != 0 {
            throw PMError.GitError(exitCode: pullResult)
        }
    case .Version(let version):

        let versionRange = VersionRange()
        for ver in version {
            try versionRange.combine(ver)
        }
        let versions = fetchVersions(pkg)

        guard let version = try chooseVersion(versions: versions, versionRange: versionRange, lockedPayload:lock?.payloadMatching(key: "git"), update: false) else {
            throw PMError.InvalidVersion
        }
        let pullResult = logAndExecute(command: "cd 'external/\(pkg.name!)' && git checkout '\(version)'")
            if pullResult != 0 {
                throw PMError.GitError(exitCode: pullResult)
        }
    }
}

// Checkout a git repository and all its submodules
//
// This only checks out the default branch and calls updateDependency() for
// fetching the correct branch/tag
func fetchGitDependency(_ pkg: ExternalDependency, lock: LockedPackage?) throws {

    // If the url has been overridden checkout that repo instead
    if let lock = lock where lock.gitPayload.overrideURL != nil {
        print("Package \(pkg.name!) repo URL overridden: \(lock.gitPayload.overrideURL!)")
        let cloneResult = logAndExecute(command: "git clone --recurse-submodules '\(lock.gitPayload.overrideURL!)' 'external/\(pkg.name!)'")
        if cloneResult != 0 {
            throw PMError.GitError(exitCode: cloneResult)
        }
        return
    }

    let cloneResult = logAndExecute(command: "git clone --recurse-submodules '\(pkg.url)' 'external/\(pkg.name!)'")
    if cloneResult != 0 {
        throw PMError.GitError(exitCode: cloneResult)
    }

    try updateDependency(pkg, lock: lock, firstTime: true)
}
func updateGitLockPackage(pkg: ExternalDependency, lockedPackage: inout LockedPackage) {
        guard let usedCommitID = getCurrentCommitID(pkg) else {
            print("ERROR: Corrupt git repository for package \(pkg.name!)")
            exit(1)
        }
        lockedPackage.gitPayload.usedCommitID = usedCommitID
}
func getCurrentCommitID(_ pkg: ExternalDependency) -> String? {
    if !FS.fileExists(path: Path("external/\(pkg.name!)")) {
        return nil
    }
    let fp = popen("cd 'external/\(pkg.name!)' && git rev-parse HEAD", "r")
    guard fp != nil else {
        return nil
    }
    defer {
        pclose(fp)
    }
    var buffer = [CChar](repeating: 0, count: 255)
    while feof(fp) == 0 {
        if fgets(&buffer, 255, fp) == nil {
            break
        }
        if let commitID = String(validatingUTF8: buffer) {
            return commitID.subString(toIndex: commitID.index(commitID.startIndex, offsetBy: commitID.characters.count - 1))
        }
    }
    return nil
}
