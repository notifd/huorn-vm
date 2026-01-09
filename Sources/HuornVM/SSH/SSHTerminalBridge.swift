// HuornVM - SSH Terminal Bridge

import Foundation
import SwiftTerm

/// Bridge between SSH connection and SwiftTerm terminal view
@MainActor
public class SSHTerminalBridge {
    /// The SSH connection
    private let connection: SSHConnection

    /// Weak reference to terminal view (for sending output)
    private weak var terminalDelegate: LocalProcessTerminalViewDelegate?

    public init(connection: SSHConnection) {
        self.connection = connection
        setupDataHandlers()
    }

    /// Attach to a terminal view delegate
    public func attach(to delegate: LocalProcessTerminalViewDelegate) {
        self.terminalDelegate = delegate
    }

    /// Send input from terminal to SSH
    public func send(_ data: ArraySlice<UInt8>) {
        connection.sendBytes(Array(data))
    }

    /// Send string from terminal to SSH
    public func send(_ text: String) {
        connection.send(text)
    }

    /// Disconnect
    public func disconnect() {
        connection.disconnect()
    }

    /// Whether the connection is active
    public var isConnected: Bool {
        connection.isConnected
    }

    // MARK: - Private

    private func setupDataHandlers() {
        connection.onData = { [weak self] bytes in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.terminalDelegate?.send(source: self, data: ArraySlice(bytes))
            }
        }
    }
}

/// Protocol for terminal view data handling
public protocol LocalProcessTerminalViewDelegate: AnyObject {
    func send(source: SSHTerminalBridge, data: ArraySlice<UInt8>)
}
