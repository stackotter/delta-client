// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DeltaClient",
  platforms: [.macOS(.v11)],
  products: [
    .executable(
      name: "DeltaClient",
      targets: ["DeltaClient"]),
    .library(
      name: "DeltaCore",
      targets: ["DeltaCore", "DeltaCoreC"]),
  ],
  dependencies: [
    // DeltaCore dependencies
    .package(name: "ZIPFoundation", url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
    .package(name: "IDZSwiftCommonCrypto", url: "https://github.com/iosdevzone/IDZSwiftCommonCrypto", from: "0.13.1"),
    .package(name: "DeltaLogger", url: "https://github.com/stackotter/delta-logger", .branch("main")),
    .package(name: "NioDNS", url: "https://github.com/OpenKitten/NioDNS", from: "1.0.2"),
    .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
    .package(name: "swift-collections", url: "https://github.com/apple/swift-collections.git", from: "0.0.7"),
  ],
  targets: [
    .target(
      name: "DeltaClient",
      dependencies: ["DeltaCore"]),
    
    .target(
      name: "DeltaCore",
      dependencies: [
        "DeltaCoreC",
        "DeltaLogger",
        "ZIPFoundation",
        "IDZSwiftCommonCrypto",
        "NioDNS",
        "SwiftProtobuf",
        .product(name: "Collections", package: "swift-collections")],
      exclude: [
        "Resources/Cache/BlockModelPalette.proto",
        "Resources/Cache/Compile.sh"],
      resources: [.process("Render/Renderer/Shader/ChunkShaders.metal")]),
    .target(
      name: "DeltaCoreC",
      publicHeadersPath: "."),
  ]
)
