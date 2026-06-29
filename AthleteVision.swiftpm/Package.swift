// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AthleteVision",
    platforms: [.iOS("17.0")],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
