// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SheerUI",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SheerUI", targets: ["SheerUI"])
    ],
    targets: [
        .target(name: "SheerUI", resources: [.process("Resources")]),
        .testTarget(name: "SheerUITests", dependencies: ["SheerUI"])
    ],
    swiftLanguageModes: [.v6]
)
