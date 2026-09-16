// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KitoScreens",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8), .visionOS(.v1)],
    products: [.library(name: "KitoScreens", targets: ["KitoScreens"])],
    dependencies: [
        // Pinned to main until KitoFields 1.3.0 and KitoButtons 1.4.0 are tagged, then switched to versions.
        .package(url: "https://github.com/wykeenjenga/KitoFields.git", branch: "main"),
        .package(url: "https://github.com/wykeenjenga/KitoButtons.git", branch: "main"),
    ],
    targets: [
        .target(name: "KitoScreens", dependencies: ["KitoFields", "KitoButtons"], path: "Sources/KitoScreens"),
        .testTarget(name: "KitoScreensTests", dependencies: ["KitoScreens"], path: "Tests/KitoScreensTests"),
    ]
)
