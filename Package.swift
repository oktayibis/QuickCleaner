// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuickCleaner",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "QuickCleaner", targets: ["QuickCleaner"])
    ],
    targets: [
        .executableTarget(
            name: "QuickCleaner",
            path: "QuickCleaner",
            exclude: ["QuickCleaner.entitlements"],
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "QuickCleanerTests",
            dependencies: ["QuickCleaner"],
            path: "QuickCleanerTests"
        )
    ]
)

