// HuornVM - VM Loader

import Foundation
import Virtualization

/// Loads VMs from bundle directories
public enum VMLoader {
    /// Load a VM from a bundle directory
    @available(macOS 15.0, *)
    @MainActor
    public static func load(from bundleURL: URL) async throws -> VirtualMachine {
        guard FileManager.default.fileExists(atPath: bundleURL.path) else {
            throw VMError.bundleNotFound(bundleURL)
        }

        // Load configuration
        let configPath = bundleURL.appendingPathComponent("config.json")
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw VMError.bundleInvalid("Missing config.json")
        }

        let configData = try Data(contentsOf: configPath)
        let decoder = JSONDecoder()
        let codableConfig = try decoder.decode(VMConfigurationCodable.self, from: configData)
        let configuration = codableConfig.toConfiguration()

        // Verify required files exist
        let requiredFiles = ["hardware_model.bin", "machine_id.bin", "auxiliary.img", "disk.img"]
        for file in requiredFiles {
            let path = bundleURL.appendingPathComponent(file)
            guard FileManager.default.fileExists(atPath: path.path) else {
                throw VMError.bundleInvalid("Missing required file: \(file)")
            }
        }

        return VirtualMachine(bundleURL: bundleURL, configuration: configuration)
    }

    /// List all VM bundles in the default location
    public static func listAll() async throws -> [VMInfo] {
        let vmDir = defaultStorageDirectory

        guard FileManager.default.fileExists(atPath: vmDir.path) else {
            return []
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: vmDir,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey]
        )

        var vms: [VMInfo] = []
        for url in contents {
            guard url.pathExtension == "huornvm" else { continue }

            if let info = try? await loadVMInfo(from: url) {
                vms.append(info)
            }
        }

        return vms.sorted { $0.lastModified > $1.lastModified }
    }

    /// Load VM info without fully loading the VM
    private static func loadVMInfo(from bundleURL: URL) async throws -> VMInfo {
        let configPath = bundleURL.appendingPathComponent("config.json")

        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw VMError.bundleInvalid("Missing config.json")
        }

        let configData = try Data(contentsOf: configPath)
        let decoder = JSONDecoder()
        let codableConfig = try decoder.decode(VMConfigurationCodable.self, from: configData)

        // Get disk size
        let diskPath = bundleURL.appendingPathComponent("disk.img")
        var diskSize: UInt64 = 0
        if let attrs = try? FileManager.default.attributesOfItem(atPath: diskPath.path),
           let size = attrs[.size] as? UInt64 {
            diskSize = size
        }

        // Get modification date
        var lastModified = Date()
        if let attrs = try? FileManager.default.attributesOfItem(atPath: bundleURL.path),
           let date = attrs[.modificationDate] as? Date {
            lastModified = date
        }

        return VMInfo(
            bundleURL: bundleURL,
            name: codableConfig.name,
            cpuCores: codableConfig.cpuCores,
            memoryBytes: codableConfig.memoryBytes,
            diskSizeBytes: diskSize,
            lastModified: lastModified
        )
    }

    /// Default storage directory for VMs
    public static var defaultStorageDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("HuornVM/VMs", isDirectory: true)
    }
}

// MARK: - Codable configuration for loading

private struct VMConfigurationCodable: Codable {
    var name: String
    var cpuCores: Int
    var memoryBytes: UInt64
    var diskSizeBytes: UInt64
    var displayWidth: Int
    var displayHeight: Int
    var displayPPI: Int
    var sharedFolders: [SharedFolderCodable]

    func toConfiguration() -> VMConfiguration {
        VMConfiguration(
            name: name,
            cpuCores: cpuCores,
            memoryBytes: memoryBytes,
            diskSizeBytes: diskSizeBytes,
            displayWidth: displayWidth,
            displayHeight: displayHeight,
            displayPPI: displayPPI,
            sharedFolders: sharedFolders.map { $0.toConfig() }
        )
    }
}

private struct SharedFolderCodable: Codable {
    var hostPath: String
    var guestTag: String
    var readOnly: Bool

    func toConfig() -> SharedFolderConfig {
        SharedFolderConfig(
            hostPath: URL(fileURLWithPath: hostPath),
            guestTag: guestTag,
            readOnly: readOnly
        )
    }
}
