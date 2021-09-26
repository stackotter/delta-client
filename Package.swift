// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DeltaClient",
  platforms: [.macOS(.v11)],
  dependencies: [
    .package(name: "DeltaCore", path: "./delta-core"),
  ],
  targets: [
    .target(
      name: "DeltaClient",
      dependencies: ["DeltaCore"]),
  ]
)
