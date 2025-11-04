// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Kapture",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Kapture",
            targets: ["Kapture"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Kapture",
            path: "Kapture",
            exclude: ["App"] // Exclude app entry point for package tests
        ),
        .testTarget(
            name: "KaptureTests",
            dependencies: ["Kapture"],
            path: "KaptureTests"
        ),
    ]
)

