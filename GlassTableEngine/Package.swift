// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GlassTableEngine",
    products: [
        .library(name: "GlassTableEngine", targets: ["GlassTableEngine"]),
    ],
    targets: [
        .target(name: "GlassTableEngine"),
        .testTarget(
            name: "GlassTableEngineTests",
            dependencies: ["GlassTableEngine"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
