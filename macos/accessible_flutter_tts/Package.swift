// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "accessible_flutter_tts",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "accessible-flutter-tts", targets: ["accessible_flutter_tts"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "accessible_flutter_tts",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
