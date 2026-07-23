// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "XPoster",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "XPoster",
            path: "Sources/XPoster"
        )
    ]
)
