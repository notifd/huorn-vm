// HuornVM - Console Terminal Bridge

import Foundation
import SwiftTerm

/// Bridge between serial console and SwiftTerm terminal view
@MainActor
public class ConsoleTerminalBridge {
    /// The serial console
    private let console: SerialConsole

    /// Weak reference to terminal view delegate
    private weak var terminalDelegate: ConsoleTerminalDelegate?

    public init(console: SerialConsole) {
        self.console = console
        setupDataHandlers()
    }

    /// Attach to a terminal delegate
    public func attach(to delegate: ConsoleTerminalDelegate) {
        self.terminalDelegate = delegate
    }

    /// Send input from terminal to console
    public func send(_ data: ArraySlice<UInt8>) {
        console.sendBytes(Array(data))
    }

    /// Send string from terminal to console
    public func send(_ text: String) {
        console.send(text)
    }

    /// Get the console output buffer
    public var outputBuffer: String {
        console.outputBuffer
    }

    /// Clear the console buffer
    public func clearBuffer() {
        console.clearBuffer()
    }

    // MARK: - Private

    private func setupDataHandlers() {
        console.onData = { [weak self] bytes in
            DispatchQueue.main.async {
                self?.terminalDelegate?.consoleDidReceive(data: ArraySlice(bytes))
            }
        }
    }
}

/// Protocol for console terminal data handling
public protocol ConsoleTerminalDelegate: AnyObject {
    func consoleDidReceive(data: ArraySlice<UInt8>)
}
