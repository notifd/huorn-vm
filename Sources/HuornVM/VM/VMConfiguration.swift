// HuornVM - VM Configuration

import Foundation

/// Configuration for a virtual machine
public struct VMConfiguration: Sendable {
    public var name: String
    public var cpuCores: Int
    public var memoryBytes: UInt64
    public var diskSizeBytes: UInt64
    public var displayWidth: Int
    public var displayHeight: Int
    public var displayPPI: Int
    public var sharedFolders: [SharedFolderConfig]

    /// Default VM configuration
    public static var `default`: VMConfiguration {
        VMConfiguration(
            name: "macOS VM",
            cpuCores: min(4, ProcessInfo.processInfo.processorCount),
            memoryBytes: 8 * 1024 * 1024 * 1024, // 8GB
            diskSizeBytes: 64 * 1024 * 1024 * 1024, // 64GB
            displayWidth: 1920,
            displayHeight: 1080,
            displayPPI: 144,
            sharedFolders: []
        )
    }

    public init(
        name: String,
        cpuCores: Int,
        memoryBytes: UInt64,
        diskSizeBytes: UInt64,
        displayWidth: Int = 1920,
        displayHeight: Int = 1080,
        displayPPI: Int = 144,
        sharedFolders: [SharedFolderConfig] = []
    ) {
        self.name = name
        self.cpuCores = cpuCores
        self.memoryBytes = memoryBytes
        self.diskSizeBytes = diskSizeBytes
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.displayPPI = displayPPI
        self.sharedFolders = sharedFolders
    }
}

/// Shared folder configuration
public struct SharedFolderConfig: Sendable {
    public var hostPath: URL
    public var guestTag: String
    public var readOnly: Bool

    public init(hostPath: URL, guestTag: String, readOnly: Bool = false) {
        self.hostPath = hostPath
        self.guestTag = guestTag
        self.readOnly = readOnly
    }
}
