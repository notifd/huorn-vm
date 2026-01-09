// HuornVM - Swift framework for macOS VM management
// https://github.com/notifd/huorn-vm

@_exported import Foundation
@_exported import Virtualization

/// HuornVM framework version
public let huornVMVersion = "0.1.0"

/// Main entry point for VM operations
public enum HuornVM {
    /// Create a new VM builder
    @available(macOS 15.0, *)
    public static func builder() -> VMBuilder {
        VMBuilder()
    }

    /// Load an existing VM from bundle
    @available(macOS 15.0, *)
    @MainActor
    public static func load(from bundleURL: URL) async throws -> VirtualMachine {
        try await VMLoader.load(from: bundleURL)
    }

    /// List all VM bundles in default location
    public static func listVMs() async throws -> [VMInfo] {
        try await VMLoader.listAll()
    }

    /// Check if virtualization is supported on this Mac
    public static var isSupported: Bool {
        VZVirtualMachine.isSupported
    }

    /// Default storage directory for VMs
    public static var storageDirectory: URL {
        VMLoader.defaultStorageDirectory
    }
}
