// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ConnectsMenu",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ConnectsMenu", targets: ["ConnectsMenu"])
    ],
    targets: [
        .executableTarget(
            name: "ConnectsMenu",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreGraphics")
            ]
        )
    ]
)
