// HuornVM - VM Builder

import Foundation
import Virtualization

/// Builder for creating virtual machines
public class VMBuilder {
    private var ipswURL: URL?
    private var bundleURL: URL?
    private var configuration: VMConfiguration = .default

    public init() {}

    /// Create VM from IPSW restore image
    public func fromIPSW(url: URL) -> VMBuilder {
        self.ipswURL = url
        return self
    }

    /// Set the bundle location for storing VM files
    public func withBundle(at url: URL) -> VMBuilder {
        self.bundleURL = url
        return self
    }

    /// Set VM name
    public func withName(_ name: String) -> VMBuilder {
        configuration.name = name
        return self
    }

    /// Set CPU core count
    public func withCPUs(_ count: Int) -> VMBuilder {
        configuration.cpuCores = min(count, ProcessInfo.processInfo.processorCount)
        return self
    }

    /// Set memory size in bytes
    public func withMemory(_ bytes: UInt64) -> VMBuilder {
        configuration.memoryBytes = bytes
        return self
    }

    /// Set disk size in bytes
    public func withDiskSize(_ bytes: UInt64) -> VMBuilder {
        configuration.diskSizeBytes = bytes
        return self
    }

    /// Set display resolution
    public func withDisplay(width: Int, height: Int, ppi: Int = 144) -> VMBuilder {
        configuration.displayWidth = width
        configuration.displayHeight = height
        configuration.displayPPI = ppi
        return self
    }

    /// Add a shared folder
    public func withSharedFolder(hostPath: String, guestTag: String, readOnly: Bool = false) -> VMBuilder {
        let folder = SharedFolderConfig(
            hostPath: URL(fileURLWithPath: hostPath),
            guestTag: guestTag,
            readOnly: readOnly
        )
        configuration.sharedFolders.append(folder)
        return self
    }

    /// Build the virtual machine
    @available(macOS 15.0, *)
    @MainActor
    public func build() async throws -> VirtualMachine {
        guard VZVirtualMachine.isSupported else {
            throw VMError.virtualizationNotSupported
        }

        // Determine bundle URL
        let bundle = bundleURL ?? defaultBundleURL()

        // Create bundle directory
        try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: true)

        if let ipsw = ipswURL {
            // Install from IPSW
            return try await installFromIPSW(ipsw, to: bundle)
        } else {
            throw VMError.configurationInvalid("No IPSW URL provided. Use fromIPSW() to specify restore image.")
        }
    }

    // MARK: - Private

    private func defaultBundleURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vmDir = appSupport.appendingPathComponent("HuornVM/VMs", isDirectory: true)
        return vmDir.appendingPathComponent("\(configuration.name).huornvm", isDirectory: true)
    }

    @available(macOS 15.0, *)
    @MainActor
    private func installFromIPSW(_ ipswURL: URL, to bundleURL: URL) async throws -> VirtualMachine {
        // Load restore image
        let restoreImage = try await VZMacOSRestoreImage.image(from: ipswURL)

        guard let requirements = restoreImage.mostFeaturefulSupportedConfiguration else {
            throw VMError.configurationInvalid("No supported configuration found for this restore image")
        }

        // Validate requirements
        guard requirements.minimumSupportedCPUCount <= configuration.cpuCores else {
            throw VMError.configurationInvalid("macOS requires at least \(requirements.minimumSupportedCPUCount) CPU cores")
        }

        guard requirements.minimumSupportedMemorySize <= configuration.memoryBytes else {
            throw VMError.configurationInvalid("macOS requires at least \(requirements.minimumSupportedMemorySize / 1024 / 1024 / 1024) GB of memory")
        }

        // Create disk image
        let diskPath = bundleURL.appendingPathComponent("disk.img")
        try createDiskImage(at: diskPath, size: configuration.diskSizeBytes)

        // Create auxiliary storage
        let auxiliaryPath = bundleURL.appendingPathComponent("auxiliary.img")
        let auxiliaryStorage = try VZMacAuxiliaryStorage(
            creatingStorageAt: auxiliaryPath,
            hardwareModel: requirements.hardwareModel,
            options: []
        )

        // Save hardware model
        let hardwareModelPath = bundleURL.appendingPathComponent("hardware_model.bin")
        try requirements.hardwareModel.dataRepresentation.write(to: hardwareModelPath)

        // Create machine identifier
        let machineIdPath = bundleURL.appendingPathComponent("machine_id.bin")
        let machineIdentifier = VZMacMachineIdentifier()
        try machineIdentifier.dataRepresentation.write(to: machineIdPath)

        // Create VZ configuration
        let vzConfig = VZVirtualMachineConfiguration()
        vzConfig.cpuCount = configuration.cpuCores
        vzConfig.memorySize = configuration.memoryBytes

        // Platform
        let platform = VZMacPlatformConfiguration()
        platform.hardwareModel = requirements.hardwareModel
        platform.auxiliaryStorage = auxiliaryStorage
        platform.machineIdentifier = machineIdentifier
        vzConfig.platform = platform

        // Boot loader
        vzConfig.bootLoader = VZMacOSBootLoader()

        // Storage
        let diskAttachment = try VZDiskImageStorageDeviceAttachment(url: diskPath, readOnly: false)
        vzConfig.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)]

        // Network
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        vzConfig.networkDevices = [networkDevice]

        // Graphics
        let graphics = VZMacGraphicsDeviceConfiguration()
        graphics.displays = [
            VZMacGraphicsDisplayConfiguration(
                widthInPixels: configuration.displayWidth,
                heightInPixels: configuration.displayHeight,
                pixelsPerInch: configuration.displayPPI
            )
        ]
        vzConfig.graphicsDevices = [graphics]

        // Input devices
        vzConfig.keyboards = [VZUSBKeyboardConfiguration()]
        vzConfig.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]

        // Audio
        let audioDevice = VZVirtioSoundDeviceConfiguration()
        let outputStream = VZVirtioSoundDeviceOutputStreamConfiguration()
        outputStream.sink = VZHostAudioOutputStreamSink()
        audioDevice.streams = [outputStream]
        vzConfig.audioDevices = [audioDevice]

        // Shared folders
        if !configuration.sharedFolders.isEmpty {
            var directories: [String: VZSharedDirectory] = [:]
            for folder in configuration.sharedFolders {
                directories[folder.guestTag] = VZSharedDirectory(url: folder.hostPath, readOnly: folder.readOnly)
            }
            let share = VZMultipleDirectoryShare(directories: directories)
            let sharingDevice = VZVirtioFileSystemDeviceConfiguration(tag: VZVirtioFileSystemDeviceConfiguration.macOSGuestAutomountTag)
            sharingDevice.share = share
            vzConfig.directorySharingDevices = [sharingDevice]
        }

        // Validate
        try vzConfig.validate()

        // Install macOS
        let vzMachine = VZVirtualMachine(configuration: vzConfig)
        let installer = VZMacOSInstaller(virtualMachine: vzMachine, restoringFromImageAt: ipswURL)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            installer.install { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Save configuration
        let configPath = bundleURL.appendingPathComponent("config.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let configData = try encoder.encode(VMConfigurationCodable(from: configuration))
        try configData.write(to: configPath)

        return VirtualMachine(bundleURL: bundleURL, configuration: configuration, vzMachine: vzMachine)
    }

    private func createDiskImage(at path: URL, size: UInt64) throws {
        let fd = open(path.path, O_RDWR | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR)
        guard fd >= 0 else {
            throw VMError.diskCreationFailed("Failed to create disk file at \(path.path)")
        }
        defer { close(fd) }

        if ftruncate(fd, Int64(size)) != 0 {
            throw VMError.diskCreationFailed("Failed to set disk size")
        }
    }
}

// MARK: - Codable wrapper for configuration persistence

private struct VMConfigurationCodable: Codable {
    var name: String
    var cpuCores: Int
    var memoryBytes: UInt64
    var diskSizeBytes: UInt64
    var displayWidth: Int
    var displayHeight: Int
    var displayPPI: Int
    var sharedFolders: [SharedFolderCodable]

    init(from config: VMConfiguration) {
        self.name = config.name
        self.cpuCores = config.cpuCores
        self.memoryBytes = config.memoryBytes
        self.diskSizeBytes = config.diskSizeBytes
        self.displayWidth = config.displayWidth
        self.displayHeight = config.displayHeight
        self.displayPPI = config.displayPPI
        self.sharedFolders = config.sharedFolders.map { SharedFolderCodable(from: $0) }
    }

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

    init(from config: SharedFolderConfig) {
        self.hostPath = config.hostPath.path
        self.guestTag = config.guestTag
        self.readOnly = config.readOnly
    }

    func toConfig() -> SharedFolderConfig {
        SharedFolderConfig(
            hostPath: URL(fileURLWithPath: hostPath),
            guestTag: guestTag,
            readOnly: readOnly
        )
    }
}
