// HuornVM - VM State and Error Types

import Foundation

/// VM running state
public enum VMState: String, Sendable {
    case created
    case starting
    case running
    case pausing
    case paused
    case stopping
    case stopped
    case error
}

/// Errors that can occur during VM operations
public enum VMError: LocalizedError {
    case virtualizationNotSupported
    case configurationInvalid(String)
    case startFailed(String)
    case stopFailed(String)
    case pauseFailed(String)
    case resumeFailed(String)
    case diskCreationFailed(String)
    case bundleNotFound(URL)
    case bundleInvalid(String)
    case sshConnectionFailed(String)
    case sshTimeout
    case ipAddressNotFound

    public var errorDescription: String? {
        switch self {
        case .virtualizationNotSupported:
            return "Virtualization is not supported on this Mac"
        case .configurationInvalid(let reason):
            return "Invalid VM configuration: \(reason)"
        case .startFailed(let reason):
            return "Failed to start VM: \(reason)"
        case .stopFailed(let reason):
            return "Failed to stop VM: \(reason)"
        case .pauseFailed(let reason):
            return "Failed to pause VM: \(reason)"
        case .resumeFailed(let reason):
            return "Failed to resume VM: \(reason)"
        case .diskCreationFailed(let reason):
            return "Failed to create disk: \(reason)"
        case .bundleNotFound(let url):
            return "VM bundle not found at: \(url.path)"
        case .bundleInvalid(let reason):
            return "Invalid VM bundle: \(reason)"
        case .sshConnectionFailed(let reason):
            return "SSH connection failed: \(reason)"
        case .sshTimeout:
            return "SSH connection timed out"
        case .ipAddressNotFound:
            return "Could not determine VM IP address"
        }
    }
}
