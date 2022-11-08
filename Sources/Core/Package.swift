// swift-tools-version:5.5

import PackageDescription

var dependencies: [Package.Dependency] = [
  .package(name: "ZIPFoundation", url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
  .package(name: "DeltaLogger", url: "https://github.com/stackotter/delta-logger", .branch("main")),
  .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
  .package(name: "swift-collections", url: "https://github.com/apple/swift-collections.git", from: "0.0.7"),
  .package(name: "swift-atomics", url: "https://github.com/apple/swift-atomics.git", from: "1.0.2"),
  .package(name: "FirebladeECS", url: "https://github.com/stackotter/ecs.git", .branch("master")),
  .package(name: "ZippyJSON", url: "https://github.com/michaeleisel/ZippyJSON", from: "1.2.4"),
  .package(url: "https://github.com/pointfreeco/swift-parsing", .exact("0.8.0")),
  .package(url: "https://github.com/stackotter/swift-openssl", from: "4.0.4"),
  .package(url: "https://github.com/stackotter/fireblade-math.git", branch: "matrix2x2"),
  .package(url: "https://github.com/seznam/swift-resolver", from: "0.3.0"),
  .package(url: "https://github.com/fourplusone/swift-package-zlib", from: "1.2.11"),
  .package(url: "https://github.com/koher/swift-image.git", from: "0.7.1"),
  .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.13.0"),
  .package(url: "https://github.com/kelvin13/swift-png", from: "4.0.2")
]

#if swift(>=5.6)
// Add linter if swift version is high enough
dependencies.append(.package(url: "https://github.com/stackotter/swift-lint-plugin", from: "0.1.0"))
#endif

let package = Package(
  name: "DeltaCore",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "DeltaCore", type: .dynamic, targets: ["DeltaCore", "DeltaRenderer"]),
    .library(name: "StaticDeltaCore", type: .static, targets: ["DeltaCore", "DeltaRenderer"]),
  ],
  dependencies: dependencies,
  targets: [
    .target(
      name: "DeltaCore",
      dependencies: [
        "DeltaLogger",
        "ZIPFoundation",
        "SwiftProtobuf",
        "FirebladeECS",
        .product(name: "OpenCombine", package: "OpenCombine", condition: .when(platforms: [.linux])),
        .product(name: "Atomics", package: "swift-atomics"),
        .product(name: "ZippyJSON", package: "ZippyJSON", condition: .when(platforms: [.macOS, .iOS, .tvOS])),
        .product(name: "Parsing", package: "swift-parsing"),
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(name: "OpenSSL", package: "swift-openssl"),
        .product(name: "FirebladeMath", package: "fireblade-math"),
        .product(name: "Resolver", package: "swift-resolver"),
        .product(name: "Z", package: "swift-package-zlib"),
        .product(name: "SwiftImage", package: "swift-image"),
        .product(name: "PNG", package: "swift-png")
      ],
      path: "Sources",
      exclude: [
        "Cache/Protobuf/BlockModelPalette.proto",
        "Cache/Protobuf/BlockRegistry.proto",
        "Cache/Protobuf/Compile.sh"
      ]
    ),

    .target(
      name: "DeltaRenderer",
      dependencies: [
        "DeltaCore"
      ],
      path: "Renderer",
      resources: [
        .process("Shader/")
      ]
    ),

    .testTarget(
      name: "DeltaCoreUnitTests",
      dependencies: ["DeltaCore"]
    )
  ]
)
