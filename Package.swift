// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KitoScreens",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v9), .visionOS(.v1)],
    products: [.library(name: "KitoScreens", targets: ["KitoScreens"])],
    dependencies: [
        .package(url: "https://github.com/wykeenjenga/KitoFields.git", from: "1.9.2"),
        .package(url: "https://github.com/wykeenjenga/KitoButtons.git", from: "1.8.1"),
    ],
    targets: [
        .target(name: "KitoScreens", dependencies: ["KitoFields", "KitoButtons"], path: "Sources/KitoScreens", resources: [.process("Resources")]),
        .testTarget(name: "KitoScreensTests", dependencies: ["KitoScreens"], path: "Tests/KitoScreensTests"),
    ]
)
