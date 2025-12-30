// swift-tools-version: 5.9
// This package file is for reference - add dependencies via Xcode's SPM integration

import PackageDescription

let package = Package(
    name: "Talk",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Talk", targets: ["Talk"])
    ],
    dependencies: [
        // Global hotkey configuration UI
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),

        // Launch at login
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Talk",
            dependencies: [
                "KeyboardShortcuts",
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
            ],
            path: "Talk",
            exclude: ["Info.plist", "Talk.entitlements"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
