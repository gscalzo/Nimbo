// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Nimbo",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "nimbo", targets: ["NimboCLI"])
    ],
    dependencies: [
        // TODO: Add minimal dependencies when needed:
        // .package(url: "https://github.com/jamesrochabrun/SwiftOpenAI", from: "0.8.0"),
        // .package(url: "https://github.com/swiftlang/swift-subprocess", from: "0.0.3"),
    ],
    targets: [
        .executableTarget(
            name: "NimboCLI",
            dependencies: [
                // "SwiftOpenAI",
                // .product(name: "Subprocess", package: "swift-subprocess"),
            ],
            path: "Sources/NimboCLI"
        )
    ]
)

