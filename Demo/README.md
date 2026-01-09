# HuornVM Demo

Demo application showcasing the HuornVM framework capabilities.

## Features

- **Split-pane layout**: SSH terminal on the left, VM GUI on the right
- **VM lifecycle controls**: Start, stop, pause VMs
- **SSH terminal**: Connect to running VMs via SSH
- **VM display**: Native macOS VM GUI window

## Requirements

- macOS 15.0 (Sequoia) or later
- Apple Silicon Mac
- Xcode 16.0 or later
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

## Building

```bash
cd Demo/HuornVMDemo
xcodegen generate
open HuornVMDemo.xcodeproj
```

## Usage

1. Launch the app
2. Create or load a VM (requires IPSW for macOS VM)
3. Start the VM using the controls
4. Once VM is running and has IP, click "Connect" to open SSH terminal

## Architecture

```
Demo/
└── HuornVMDemo/
    ├── Sources/
    │   ├── HuornVMDemoApp.swift    # App entry point
    │   └── ContentView.swift       # Main UI
    ├── Resources/
    │   └── HuornVMDemo.entitlements
    └── project.yml                 # xcodegen config
```
