// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacWinManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "MacWinCore", targets: ["MacWinCore"]),
        .executable(name: "MacWinManagerApp", targets: ["MacWinManagerApp"])
    ],
    targets: [
        .target(
            name: "MacWinCore"
        ),
        .executableTarget(
            name: "MacWinManagerApp",
            dependencies: ["MacWinCore"],
            exclude: [
                "Resources/AppAssets.xcassets"
            ],
            resources: [
                .copy("Resources/Catalog"),
                .copy("Resources/Icons")
            ]
        ),
        .testTarget(
            name: "MacWinCoreTests",
            dependencies: ["MacWinCore"]
        )
    ]
)
