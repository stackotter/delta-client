// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "PluginAPI",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "PluginAPI", type: .dynamic, targets: ["PluginAPI"]),
    .library(name: "StaticPluginAPI", type: .static, targets: ["PluginAPI"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "PluginAPI", dependencies: [], path: "Sources"),
  ]
)
