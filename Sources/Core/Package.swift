// swift-tools-version:5.5

import PackageDescription

var dependencies: [Package.Dependency] = [
  .package(name: "ZIPFoundation", url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
  .package(name: "DeltaLogger", url: "https://github.com/stackotter/delta-logger", .branch("main")),
  .package(name: "DNSClient", url: "https://github.com/OpenKitten/NioDNS.git", from: "2.0.0"),
  .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
  .package(name: "swift-collections", url: "https://github.com/apple/swift-collections.git", from: "0.0.7"),
  .package(name: "Concurrency", url: "https://github.com/uber/swift-concurrency.git", from: "0.7.1"),
  .package(name: "FirebladeECS", url: "https://github.com/stackotter/ecs.git", .branch("master")),
  .package(name: "FirebladeMath", url: "https://github.com/fireblade-engine/math", .branch("master")),
  .package(name: "ZippyJSON", url: "https://github.com/michaeleisel/ZippyJSON", from: "1.2.4"),
  .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
  .package(url: "https://github.com/pointfreeco/swift-parsing", .exact("0.8.0")),
  .package(url: "https://github.com/stackotter/swift-openssl", from: "4.0.4")
]

#if swift(>=5.6)
// Add linter if swift version is high enough
dependencies.append(.package(url: "https://github.com/stackotter/swift-lint-plugin", from: "0.1.0"))
#endif

let package = Package(
  name: "DeltaCore",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "DeltaCore", type: .dynamic, targets: ["DeltaCore"]),
    .library(name: "StaticDeltaCore", type: .static, targets: ["DeltaCore"])
  ],
  dependencies: dependencies,
  targets: [
    .target(
      name: "DeltaCore",
      dependencies: [
        "DeltaLogger",
        "ZIPFoundation",
        .product(name: "DNSClient", package: "DNSClient"),
        "SwiftProtobuf",
        "Concurrency",
        "FirebladeECS",
        "FirebladeMath",
        .product(name: "ZippyJSON", package: "ZippyJSON", condition: .when(platforms: [.macOS])),
        .product(name: "Parsing", package: "swift-parsing"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "OpenSSL", package: "swift-openssl")
      ],
      path: "Sources",
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
