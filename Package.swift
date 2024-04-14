// swift-tools-version:5.5

import PackageDescription

var products: [Product] = [
  .executable(
    name: "DeltaClientGtk",
    targets: ["DeltaClientGtk"]
  ),

  // Importing DynamicShim as a dependency in your own project will in effect just import
  // DeltaCore using dynamic linking
  .library(
    name: "DynamicShim",
    targets: ["DynamicShim"]
  ),

  // Importing StaticShim as a dependency in your own project will just import DeltaCore
  // using static linking
  .library(
    name: "StaticShim",
    targets: ["StaticShim"]
  )
]

#if canImport(Darwin)
products.append(.executable(
  name: "DeltaClient",
  targets: ["DeltaClient"]
))
#endif

var targets: [Target] = [
  .executableTarget(
    name: "DeltaClientGtk",
    dependencies: [
      .product(name: "DeltaCore", package: "DeltaCore"),
      .product(name: "SwiftCrossUI", package: "swift-cross-ui")
    ],
    path: "Sources/ClientGtk"
  ),

  .target(
    name: "DynamicShim",
    dependencies: [
      .product(name: "DeltaCore", package: "DeltaCore"),
    ],
    path: "Sources/Exporters/DynamicShim"
  ),

  .target(
    name: "StaticShim",
    dependencies: [
      .product(name: "StaticDeltaCore", package: "DeltaCore"),
    ],
    path: "Sources/Exporters/StaticShim"
  )
]

#if canImport(Darwin)
targets.append(.executableTarget(
  name: "DeltaClient",
  dependencies: [
    "DynamicShim",
    // .product(name: "SwordRPC", package: "SwordRPC", condition: .when(platforms: [.macOS])),
    .product(name: "ArgumentParser", package: "swift-argument-parser")
  ],
  path: "Sources/Client"
))
#endif

let package = Package(
  name: "DeltaClient",
  platforms: [.macOS(.v11), .iOS(.v15), .tvOS(.v15)],
  products: products,
  dependencies: [
    // See Notes/PluginSystem.md for more details on the architecture of the project in regards to dependencies, targets and linking
    // In short, the dependencies for DeltaCore can be found in Sources/Core/Package.swift
    .package(name: "DeltaCore", path: "Sources/Core"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/stackotter/SwordRPC", .revision("3ddf125eeb3d83cb17a6e4cda685f9c80e0d4bed")),
    .package(url: "https://github.com/stackotter/swift-cross-ui", branch: "main")
  ],
  targets: targets
)
