// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "AthleteVision",
    platforms: [.iOS("16.0")],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
