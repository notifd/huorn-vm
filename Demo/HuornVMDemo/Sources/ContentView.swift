// HuornVM Demo - Main Content View

import SwiftUI
import SwiftTerm
import HuornVM
import Virtualization

struct ContentView: View {
    @EnvironmentObject var vmManager: VMManager

    var body: some View {
        HSplitView {
            // Left: Terminal
            TerminalPane()
                .frame(minWidth: 400)

            // Right: VM GUI
            VMGuiPane()
                .frame(minWidth: 400)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - Terminal Pane

struct TerminalPane: View {
    @EnvironmentObject var vmManager: VMManager
    @State private var sshConnection: SSHConnection?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "terminal")
                Text("SSH Terminal")
                    .font(.headline)
                Spacer()

                if let vm = vmManager.virtualMachine {
                    if let ip = vm.ipAddress {
                        Text(ip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button("Connect") {
                        Task {
                            await connectSSH()
                        }
                    }
                    .disabled(vm.state != .running || vm.ipAddress == nil)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Terminal view
            if sshConnection != nil {
                SSHTerminalViewWrapper(connection: $sshConnection)
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "terminal")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Start VM and connect SSH")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }

    @MainActor
    func connectSSH() async {
        guard let vm = vmManager.virtualMachine,
              let ip = vm.ipAddress else { return }

        do {
            sshConnection = try await SSHConnection.connect(to: ip)
        } catch {
            vmManager.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - VM GUI Pane

struct VMGuiPane: View {
    @EnvironmentObject var vmManager: VMManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "desktopcomputer")
                Text("VM Display")
                    .font(.headline)
                Spacer()

                if let vm = vmManager.virtualMachine {
                    Text(vm.state.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(stateColor(vm.state))
                        .cornerRadius(4)

                    if vm.state == .stopped {
                        Button("Start") {
                            Task {
                                if #available(macOS 15.0, *) {
                                    await vmManager.startVM()
                                }
                            }
                        }
                    } else if vm.state == .running {
                        Button("Stop") {
                            Task {
                                if #available(macOS 15.0, *) {
                                    await vmManager.stopVM()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // VM View
            if let vm = vmManager.virtualMachine {
                if #available(macOS 15.0, *) {
                    if let vmView = vm.virtualMachineView {
                        VMViewWrapper(vmView: vmView)
                    } else {
                        VMPlaceholder(message: "VM not started")
                    }
                } else {
                    VMPlaceholder(message: "Requires macOS 15.0+")
                }
            } else {
                VMPlaceholder(message: "No VM loaded")
            }
        }
    }

    func stateColor(_ state: VMState) -> Color {
        switch state {
        case .running: return .green.opacity(0.3)
        case .stopped: return .gray.opacity(0.3)
        case .error: return .red.opacity(0.3)
        default: return .yellow.opacity(0.3)
        }
    }
}

struct VMPlaceholder: View {
    let message: String

    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "display")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(message)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - NSViewRepresentable Wrappers

@available(macOS 15.0, *)
struct VMViewWrapper: NSViewRepresentable {
    let vmView: VZVirtualMachineView

    func makeNSView(context: Context) -> VZVirtualMachineView {
        vmView.capturesSystemKeys = true
        return vmView
    }

    func updateNSView(_ nsView: VZVirtualMachineView, context: Context) {}
}

struct SSHTerminalViewWrapper: NSViewRepresentable {
    @Binding var connection: SSHConnection?

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminal = LocalProcessTerminalView(frame: .zero)
        return terminal
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        // Connect terminal to SSH when connection changes
    }
}

#Preview {
    ContentView()
        .environmentObject(VMManager())
}
