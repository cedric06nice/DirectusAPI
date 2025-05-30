// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DirectusAPI",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DirectusAPI",
            targets: ["DirectusAPI"]),
    ],
    targets: [
        .target(
            name: "DirectusAPI",
            resources: [
                .process("Helpers/materialToSFSymbols.json")
            ]
        ),
        .testTarget(
            name: "DirectusAPITests",
            dependencies: ["DirectusAPI"]
        ),
    ]
)
