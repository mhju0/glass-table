// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GlassTableDrills",
    products: [
        .library(name: "GlassTableDrills", targets: ["GlassTableDrills"]),
    ],
    dependencies: [
        .package(path: "../GlassTableEngine"),
    ],
    targets: [
        .target(
            name: "GlassTableDrills",
            dependencies: [.product(name: "GlassTableEngine", package: "GlassTableEngine")]
        ),
        .testTarget(name: "GlassTableDrillsTests", dependencies: ["GlassTableDrills"]),
    ]
)
