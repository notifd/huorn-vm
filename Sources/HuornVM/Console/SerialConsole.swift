// HuornVM - Serial Console

import Foundation

/// Serial console for VM I/O
@MainActor
public class SerialConsole: @unchecked Sendable {
    /// Input pipe for sending data to VM
    public let inputPipe: Pipe

    /// Output pipe for receiving data from VM
    public let outputPipe: Pipe

    /// Callback for receiving console output
    public var onOutput: ((String) -> Void)?

    /// Callback for receiving raw bytes
    public var onData: (([UInt8]) -> Void)?

    /// Console output buffer
    public private(set) var outputBuffer: String = ""

    /// Maximum buffer size (default 100KB)
    public var maxBufferSize: Int = 100_000

    public init() {
        self.inputPipe = Pipe()
        self.outputPipe = Pipe()
        setupOutputHandler()
    }

    /// Send text to the console
    public func send(_ text: String) {
        if let data = text.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(data)
        }
    }

    /// Send raw bytes to the console
    public func sendBytes(_ bytes: [UInt8]) {
        inputPipe.fileHandleForWriting.write(Data(bytes))
    }

    /// Clear the output buffer
    public func clearBuffer() {
        outputBuffer = ""
    }

    // MARK: - Private

    private func setupOutputHandler() {
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                let bytes = [UInt8](data)
                if let text = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        // Append to buffer
                        self.outputBuffer += text

                        // Trim if needed
                        if self.outputBuffer.count > self.maxBufferSize {
                            let trimAmount = self.outputBuffer.count - self.maxBufferSize + 10000
                            self.outputBuffer = String(self.outputBuffer.dropFirst(trimAmount))
                        }

                        // Notify listener
                        self.onOutput?(text)
                        self.onData?(bytes)
                    }
                }
            }
        }
    }

    /// Stop the console handler
    public func stop() {
        outputPipe.fileHandleForReading.readabilityHandler = nil
    }

    nonisolated deinit {
        // Note: The readabilityHandler will be cleaned up when Pipe is deallocated
    }
}
