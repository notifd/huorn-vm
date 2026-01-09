// HuornVM - SSH Connection

import Foundation

/// SSH connection to a virtual machine
@MainActor
public class SSHConnection: @unchecked Sendable {
    /// Host IP address
    public let host: String

    /// SSH port
    public let port: Int

    /// Username for authentication
    public let username: String

    /// Connection state
    public private(set) var isConnected: Bool = false

    /// Process handling the SSH session
    private var sshProcess: Process?

    /// Output pipe for reading SSH output
    private var outputPipe: Pipe?

    /// Input pipe for writing to SSH
    private var inputPipe: Pipe?

    /// Callback for receiving output
    public var onOutput: ((String) -> Void)?

    /// Callback for receiving raw bytes
    public var onData: (([UInt8]) -> Void)?

    private init(host: String, port: Int, username: String) {
        self.host = host
        self.port = port
        self.username = username
    }

    /// Connect to a host via SSH
    public static func connect(
        to host: String,
        port: Int = 22,
        username: String = "admin"
    ) async throws -> SSHConnection {
        let connection = SSHConnection(host: host, port: port, username: username)
        try await connection.establishConnection()
        return connection
    }

    /// Execute a command and return the output
    public func execute(_ command: String) async throws -> String {
        guard isConnected else {
            throw SSHError.notConnected
        }

        // Create a separate SSH process for this command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.arguments = [
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ConnectTimeout=5",
            "-p", String(port),
            "\(username)@\(host)",
            command
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw SSHError.commandFailed(errorString)
        }

        return String(data: outputData, encoding: .utf8) ?? ""
    }

    /// Send text to the interactive SSH session
    public func send(_ text: String) {
        guard let inputPipe = inputPipe else { return }
        if let data = text.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(data)
        }
    }

    /// Send raw bytes to the SSH session
    public func sendBytes(_ bytes: [UInt8]) {
        guard let inputPipe = inputPipe else { return }
        inputPipe.fileHandleForWriting.write(Data(bytes))
    }

    /// Disconnect the SSH session
    public func disconnect() {
        sshProcess?.terminate()
        sshProcess = nil
        isConnected = false
    }

    // MARK: - Private

    private func establishConnection() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.arguments = [
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ConnectTimeout=10",
            "-tt", // Force pseudo-terminal allocation
            "-p", String(port),
            "\(username)@\(host)"
        ]

        let outputPipe = Pipe()
        let inputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardInput = inputPipe
        process.standardError = errorPipe

        // Set up output handling
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                let bytes = [UInt8](data)
                if let text = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async { [weak self] in
                        self?.onOutput?(text)
                        self?.onData?(bytes)
                    }
                }
            }
        }

        try process.run()

        // Wait a bit for connection to establish
        try await Task.sleep(nanoseconds: 1_000_000_000)

        if process.isRunning {
            self.sshProcess = process
            self.outputPipe = outputPipe
            self.inputPipe = inputPipe
            self.isConnected = true
        } else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "Connection failed"
            throw SSHError.connectionFailed(errorString)
        }
    }

    nonisolated deinit {
        // Note: We can't call disconnect() here because deinit is nonisolated
        // The process will be cleaned up when the Process object is deallocated
    }
}

/// SSH-related errors
public enum SSHError: LocalizedError {
    case connectionFailed(String)
    case notConnected
    case commandFailed(String)
    case authenticationFailed
    case timeout

    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "SSH connection failed: \(reason)"
        case .notConnected:
            return "Not connected to SSH server"
        case .commandFailed(let error):
            return "SSH command failed: \(error)"
        case .authenticationFailed:
            return "SSH authentication failed"
        case .timeout:
            return "SSH connection timed out"
        }
    }
}
