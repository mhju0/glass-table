// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "AuditRunner", dependencies: [.package(path: "/Users/michaelju/Workspace/Projects/glass-table/GlassTableEngine"), .package(path: "/Users/michaelju/Workspace/Projects/glass-table/GlassTableDrills")], targets: [.executableTarget(name: "AuditRunner", dependencies: [.product(name: "GlassTableEngine", package: "GlassTableEngine"), .product(name: "GlassTableDrills", package: "GlassTableDrills")])])
