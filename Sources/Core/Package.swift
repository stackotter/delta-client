// swift-tools-version:5.5

import PackageDescription

// MARK: Dependencies

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
  .package(url: "https://github.com/stackotter/swift-image.git", branch: "master"),
  .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.13.0"),
  .package(url: "https://github.com/kelvin13/swift-png", from: "4.0.2"),
  .package(url: "https://github.com/stackotter/ASN1Parser", branch: "main")
]

#if swift(>=5.6)
dependencies.append(.package(url: "https://github.com/stackotter/swift-lint-plugin", from: "0.1.0"))
#endif

// MARK: Products

var productTargets = ["DeltaCore"]
#if canImport(Metal)
productTargets.append("DeltaRenderer")
#endif

// MARK: Targets

var targets: [Target] = [
  .target(
    name: "DeltaCore",
    dependencies: [
      "DeltaLogger",
      "ZIPFoundation",
      "SwiftProtobuf",
      "FirebladeECS",
      "ASN1Parser",
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

  .testTarget(
    name: "DeltaCoreUnitTests",
    dependencies: ["DeltaCore"]
  )
]

#if canImport(Metal)
targets.append(
  .target(
    name: "DeltaRenderer",
    dependencies: [
      "DeltaCore"
    ],
    path: "Renderer",
    resources: [
      .process("Shader/")
    ]
  )
)
#endif

let package = Package(
  name: "DeltaCore",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "DeltaCore", type: .dynamic, targets: productTargets),
    .library(name: "StaticDeltaCore", type: .static, targets: productTargets)
  ],
  dependencies: dependencies,
  targets: targets
)
