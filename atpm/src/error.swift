public enum PMError: Error, CustomStringConvertible {
	case GitError(exitCode: Int32)
	case MissingPackageCheckout
	case InvalidVersion
	case InsecurePackage
	case HTTPSTransportError(exitCode: Int32)
	case TarError(exitCode: Int32)

	public var description: String {
		switch self {
		case .GitError(let exitCode):
			return "Git returned with exit code \(exitCode)"
		case .MissingPackageCheckout:
			return "Missing checkout, run 'atpm fetch'"
		case .InvalidVersion:
			return "Version invalid"
		case .InsecurePackage:
			return "Package must be loaded over HTTPS or other secure method"
		case .HTTPSTransportError (let exitCode):
			return "An error occurred while loading an HTTPS resource \(exitCode)"
		case .TarError (let exitCode):
			return "An error occurred while untarring a binary package \(exitCode)"
		}
	}
}