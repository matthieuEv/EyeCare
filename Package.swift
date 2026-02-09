// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EyeCareMenubar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EyeCareCore",
            targets: ["EyeCareCore"]
        ),
        .executable(
            name: "EyeCareMenubar",
            targets: ["EyeCareMenubar"]
        )
    ],
    targets: [
        .target(
            name: "EyeCareCore"
        ),
        .executableTarget(
            name: "EyeCareMenubar",
            dependencies: ["EyeCareCore"]
        ),
        .testTarget(
            name: "EyeCareCoreTests",
            dependencies: ["EyeCareCore"]
        )
    ]
)
