// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Lumen",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Lumen", targets: ["Lumen"])
    ],
    targets: [
        .executableTarget(
            name: "Lumen",
            path: "Sources/Lumen",
            resources: [
                .copy("Resources/Shaders")
            ]
        )
    ]
)
