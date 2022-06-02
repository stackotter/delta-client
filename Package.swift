// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "DeltaClient",
  platforms: [.macOS(.v11)],
  products: [
    .executable(
      name: "DeltaClient",
      targets: ["DeltaClient"]
    ),
    .library(
      name: "DeltaCore",
      type: .dynamic,
      targets: ["DeltaCore"]
    ),
    .library(
      name: "StaticDeltaCore",
      type: .static,
      targets: ["DeltaCore"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/stackotter/SwordRPC", .revision("3ddf125eeb3d83cb17a6e4cda685f9c80e0d4bed")),
    .package(name: "ZIPFoundation", url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
    .package(name: "IDZSwiftCommonCrypto", url: "https://github.com/iosdevzone/IDZSwiftCommonCrypto", from: "0.13.1"),
    .package(name: "DeltaLogger", url: "https://github.com/stackotter/delta-logger", .branch("main")),
    .package(name: "NioDNS", url: "https://github.com/OpenKitten/NioDNS", from: "1.0.2"),
    .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
    .package(name: "swift-collections", url: "https://github.com/apple/swift-collections.git", from: "0.0.7"),
    .package(name: "Concurrency", url: "https://github.com/uber/swift-concurrency.git", from: "0.7.1"),
    .package(name: "FirebladeECS", url: "https://github.com/stackotter/ecs.git", .branch("master")),
    .package(name: "ZippyJSON", url: "https://github.com/michaeleisel/ZippyJSON", from: "1.2.4"),
    .package(url: "https://github.com/pointfreeco/swift-parsing", .exact("0.8.0")),
    .package(url: "https://github.com/stackotter/swift-lint-plugin", from: "0.1.0")
  ],
  targets: [
    .executableTarget(
      name: "DeltaClient",
      dependencies: [
        "SwordRPC",
        .product(name: "DeltaCore", package: "DeltaClient"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      path: "Sources/Client"
    ),
    
    .target(
      name: "DeltaCore",
      dependencies: [
        "DeltaLogger",
        "ZIPFoundation",
        "IDZSwiftCommonCrypto",
        "NioDNS",
        "SwiftProtobuf",
        "Concurrency",
        "FirebladeECS",
        "ZippyJSON",
        .product(name: "Parsing", package: "swift-parsing"),
        .product(name: "Collections", package: "swift-collections")
      ],
      path: "Sources/Core",
      exclude: [
        "Cache/Protobuf/BlockModelPalette.proto",
        "Cache/Protobuf/BlockRegistry.proto",
        "Cache/Protobuf/Compile.sh"
      ],
      resources: [
        .process("Render/Shader/")
      ]
    ),

    .testTarget(
      name: "DeltaCoreUnitTests",
      dependencies: ["DeltaCore"]
    )
  ]
)
