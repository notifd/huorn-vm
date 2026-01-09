# HuornVM

Swift framework for native macOS virtual machine management.

## Features

- **VM Lifecycle**: Create, clone, start, stop, pause macOS VMs
- **Shared Folders**: Mount host directories in guest via VirtioFS
- **SSH Terminals**: Detect VM IP and establish SSH connections
- **Serial Console**: Direct console I/O for headless operation

## Requirements

- macOS 26.0 (Tahoe) or later
- Apple Silicon Mac
- Xcode 26.0

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/notifd/huorn-vm.git", from: "0.1.0")
]
```

## Quick Start

```swift
import HuornVM

// Create VM from IPSW
let vm = try await VMBuilder()
    .fromIPSW(url: ipswURL)
    .withCPUs(4)
    .withMemory(8 * 1024 * 1024 * 1024) // 8GB
    .withSharedFolder(hostPath: "/Users/me/shared", guestTag: "shared")
    .build()

// Start VM
try await vm.start()

// Wait for SSH to become available
let ssh = try await vm.waitForSSH(timeout: 120)

// Run command
let output = try await ssh.execute("ls -la /Volumes/shared")
print(output)
```

## Demo App

The `Demo/` directory contains a sample application showing:
- SSH terminal on the left
- VM GUI window on the right

```bash
cd Demo
xcodegen generate
open HuornVMDemo.xcodeproj
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   HuornVM                       │
├─────────────────────────────────────────────────┤
│  VMManager          │  SharedFolderManager     │
│  - create/clone     │  - mount/unmount         │
│  - start/stop       │  - VirtioFS config       │
│  - pause/resume     │                          │
├─────────────────────┼──────────────────────────┤
│  SSHManager         │  ConsoleManager          │
│  - IP detection     │  - Serial I/O            │
│  - Connection pool  │  - PTY allocation        │
│  - Terminal bridge  │  - Output capture        │
├─────────────────────┴──────────────────────────┤
│           Virtualization.framework              │
└─────────────────────────────────────────────────┘
```

## License

MIT
