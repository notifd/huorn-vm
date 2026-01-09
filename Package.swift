// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HuornVM",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "HuornVM",
            targets: ["HuornVM"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "HuornVM",
            dependencies: ["SwiftTerm"]
        ),
        .testTarget(
            name: "HuornVMTests",
            dependencies: ["HuornVM"]
        ),
    ]
)
