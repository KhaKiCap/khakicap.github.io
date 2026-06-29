// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AthleteVision",
    platforms: [.iOS("16.0")],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
