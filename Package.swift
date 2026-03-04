// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ConnnectedMenu",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ConnnectedMenu", targets: ["ConnnectedMenu"])
    ],
    targets: [
        .executableTarget(
            name: "ConnnectedMenu",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreGraphics")
            ]
        )
    ]
)
