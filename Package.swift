// swift-tools-version:5.5

import PackageDescription

var dependencies: [Package.Dependency] = [
    // See Notes/PluginSystem.md for more details on the architecture of the project in regards to dependencies, targets and linking
    // In short, the dependencies for DeltaCore can be found in Sources/Core/Package.swift
    .package(name: "DeltaCore", path: "Sources/Core"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/stackotter/SwordRPC", .revision("3ddf125eeb3d83cb17a6e4cda685f9c80e0d4bed")),
]

#if swift(>=5.6)
// Add linter if swift version is high enough
dependencies.append(.package(url: "https://github.com/stackotter/swift-lint-plugin", from: "0.1.0"))
#endif

let package = Package(
  name: "DeltaClient",
  platforms: [.macOS(.v11)],
  products: [
    .executable(
      name: "DeltaClient",
      targets: ["DeltaClient"]),

    // Importing DynamicShim as a dependency in your own project will in effect just import DeltaCore, DeltaCoreC and PluginAPI but will use dynamic linking
    .library(
      name: "DynamicShim",
      targets: ["DynamicShim"]),
    
    // Importing StaticShim as a dependency in your own project will just import DeltaCore, DeltaCoreC and PluginAPI and will use static linking
    .library(
      name: "StaticShim",
      targets: ["StaticShim"]),
  ],
  dependencies: dependencies,
  targets: [
    .executableTarget(
      name: "DeltaClient",
      dependencies: [
        "DynamicShim",
        "SwordRPC",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "Sources/Client"),
    
    .target(
      name: "DynamicShim",
      dependencies: [
        .product(name: "DeltaCore", package: "DeltaCore"),
      ],
      path: "Sources/Exporters/DynamicShim"),
    
    .target(
      name: "StaticShim",
      dependencies: [
        .product(name: "StaticDeltaCore", package: "DeltaCore"),
      ],
      path: "Sources/Exporters/StaticShim"),
  ]
)
