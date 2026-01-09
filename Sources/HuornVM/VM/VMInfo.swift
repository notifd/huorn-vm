// HuornVM - VM Info

import Foundation

/// Lightweight VM information for listing without loading
public struct VMInfo: Sendable, Identifiable {
    public var id: String { bundleURL.path }

    /// Bundle URL
    public let bundleURL: URL

    /// VM name
    public let name: String

    /// CPU core count
    public let cpuCores: Int

    /// Memory in bytes
    public let memoryBytes: UInt64

    /// Disk size in bytes
    public let diskSizeBytes: UInt64

    /// Last modification date
    public let lastModified: Date

    /// Memory formatted as string
    public var memoryFormatted: String {
        let gb = Double(memoryBytes) / 1024 / 1024 / 1024
        return String(format: "%.1f GB", gb)
    }

    /// Disk size formatted as string
    public var diskSizeFormatted: String {
        let gb = Double(diskSizeBytes) / 1024 / 1024 / 1024
        return String(format: "%.1f GB", gb)
    }
}
