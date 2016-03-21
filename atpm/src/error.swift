public enum PMError: ErrorProtocol, CustomStringConvertible {
	case GitError(exitCode: Int32)
	case MissingPackageCheckout
	case InvalidVersion

	public var description: String {
		switch self {
		case .GitError(let exitCode):
			return "Git returned with exit code \(exitCode)"
		case .MissingPackageCheckout:
			return "Missing checkout, run 'atpm fetch'"
		case .InvalidVersion:
			return "Version invalid"
		}
	}
}