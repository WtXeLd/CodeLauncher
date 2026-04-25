// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodeLauncher",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "CodeLauncher",
            path: "Sources/CodeLauncher",
            linkerSettings: [
                .linkedFramework("Carbon")
            ]
        )
    ]
)
