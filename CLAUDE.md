# HuornVM

Swift framework for macOS virtual machine management using Virtualization.framework.

## Project Structure

```
huorn-vm/
├── Sources/
│   └── HuornVM/           # Framework
│       ├── VM/            # VM lifecycle management
│       ├── SharedFolder/  # Directory mounting
│       ├── SSH/           # SSH terminal connections
│       └── Console/       # Serial console access
├── Demo/                  # Demo application
│   └── HuornVMDemo/       # Terminal + GUI side by side
├── Tests/
│   └── HuornVMTests/
└── Package.swift
```

## Framework Features

### Core VM Management
- Create macOS VMs from IPSW
- Clone VMs from templates
- Start/stop/pause VM lifecycle
- Serial console I/O

### Shared Folders
- Mount host directories in guest
- VirtioFS for high-performance sharing
- Automatic mount on VM boot

### SSH Integration
- Detect VM IP address
- Establish SSH connections
- Terminal emulation for SSH sessions

## Demo App

Split-pane application showing:
- **Left**: SSH terminal into VM
- **Right**: macOS VM GUI window

## Tech Stack

- Swift 6.0
- Virtualization.framework
- SwiftTerm (terminal emulation)
- SwiftUI + AppKit
- macOS 26.0 (Tahoe)

## Development

```bash
# Build framework
swift build

# Run tests
swift test

# Build demo app
cd Demo && xcodegen && open HuornVMDemo.xcodeproj
```
