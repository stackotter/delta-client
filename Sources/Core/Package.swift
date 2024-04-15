// swift-tools-version:5.6

import PackageDescription

// MARK: Products

var productTargets = ["DeltaCore", "DeltaLogger"]
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
      "ASN1Parser",
      "CryptoSwift",
      "SwiftCPUDetect",
      .product(name: "FirebladeECS", package: "ecs"),
      .product(name: "SwiftyRequest", package: "SwiftyRequest", condition: .when(platforms: [.linux])),
      .product(name: "OpenCombine", package: "OpenCombine", condition: .when(platforms: [.linux])),
      .product(name: "Atomics", package: "swift-atomics"),
      .product(name: "ZippyJSON", package: "ZippyJSON", condition: .when(platforms: [.macOS, .iOS, .tvOS])),
      .product(name: "Parsing", package: "swift-parsing"),
      .product(name: "Collections", package: "swift-collections"),
      .product(name: "OrderedCollections", package: "swift-collections"),
      .product(name: "FirebladeMath", package: "fireblade-math"),
      .product(name: "Resolver", package: "swift-resolver"),
      .product(name: "Z", package: "swift-package-zlib"),
      .product(name: "SwiftImage", package: "swift-image"),
      .product(name: "PNG", package: "swift-png")
    ],
    path: "Sources"
  ),

  .target(
    name: "DeltaLogger",
    dependencies: [
      "Puppy",
      "Rainbow"
    ],
    path: "Logger"
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
  dependencies: [
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
    .package(url: "https://github.com/apple/swift-collections.git", from: "0.0.7"),
    .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.2"),
    .package(url: "https://github.com/stackotter/ecs.git", branch: "master"),
    .package(url: "https://github.com/michaeleisel/ZippyJSON", from: "1.2.4"),
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.12.1"),
    .package(url: "https://github.com/stackotter/fireblade-math.git", branch: "matrix2x2"),
    .package(url: "https://github.com/seznam/swift-resolver", from: "0.3.0"),
    .package(url: "https://github.com/fourplusone/swift-package-zlib", from: "1.2.11"),
    .package(url: "https://github.com/stackotter/swift-image.git", branch: "master"),
    .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.13.0"),
    .package(url: "https://github.com/stackotter/swift-png", revision: "b68a5662ef9887c8f375854720b3621f772bf8c5"),
    .package(url: "https://github.com/stackotter/ASN1Parser", branch: "main"),
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.6.0"),
    .package(url: "https://github.com/Kitura/SwiftyRequest.git", from: "3.1.0"),
    .package(url: "https://github.com/JWhitmore1/SwiftCPUDetect", branch: "main"),
    .package(url: "https://github.com/sushichop/Puppy", from: "0.6.0"),
    .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.1")
  ],
  targets: targets
)
