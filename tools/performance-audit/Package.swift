// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GTPerf",
    dependencies: [
        .package(path: "../../GlassTableEngine"),
        .package(path: "../../GlassTableDrills"),
    ],
    targets: [.executableTarget(name: "GTPerf", dependencies: ["GlassTableEngine", "GlassTableDrills"])])
