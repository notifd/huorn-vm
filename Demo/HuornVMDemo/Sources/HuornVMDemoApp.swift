// HuornVM Demo Application

import SwiftUI
import HuornVM

@main
struct HuornVMDemoApp: App {
    @StateObject private var vmManager = VMManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vmManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}

/// VM Manager for the demo app
@MainActor
class VMManager: ObservableObject {
    @Published var virtualMachine: VirtualMachine?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var vmList: [VMInfo] = []

    init() {
        Task {
            await loadVMList()
        }
    }

    func loadVMList() async {
        do {
            vmList = try await HuornVM.listVMs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @available(macOS 15.0, *)
    func loadVM(from url: URL) async {
        isLoading = true
        defer { isLoading = false }

        do {
            virtualMachine = try await HuornVM.load(from: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @available(macOS 15.0, *)
    func startVM() async {
        guard let vm = virtualMachine else { return }

        do {
            try await vm.start()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @available(macOS 15.0, *)
    func stopVM() async {
        guard let vm = virtualMachine else { return }

        do {
            try await vm.stop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
