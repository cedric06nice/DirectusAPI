// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DirectusAPI",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "DirectusAPI", targets: ["DirectusAPI"])
    ],
    dependencies: [
        .package(url: "https://github.com/cedric06nice/DirectusAPIMacros.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "DirectusAPI",
            dependencies: [
                .product(name: "DirectusAPIMacros", package: "DirectusAPIMacros")
            ],
            resources: [
                .process("DirectusIcons/GoogleFonts/Fonts/")
            ]
        ),
        .testTarget(
            name: "DirectusAPITests",
            dependencies: ["DirectusAPI"]
        )
    ]
)
