// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "DeltaCore",
  platforms: [.macOS(.v11)],
  products: [
    .library(
      name: "DeltaCore",
      targets: ["DeltaCore"])
  ],
  dependencies: [
    .package(
      name: "SwiftProtobuf",
      url: "https://github.com/apple/swift-protobuf",
      from: "1.17.0"),
    .package(
      name: "Zip",
      url: "https://github.com/marmelroy/Zip",
      from: "2.1.1"),
    .package(
      name: "IDZSwiftCommonCrypto",
      url: "https://github.com/iosdevzone/IDZSwiftCommonCrypto",
      from: "0.13.1"),
    .package(
      name: "Puppy",
      url: "https://github.com/stackotter/Puppy",
      .revision("220efa559042f5b7dc99cf089bd4dbb31e217371"))
  ],
  targets: [
    .target(
      name: "DeltaCore",
      dependencies: [
        "DeltaCoreC",
        "SwiftProtobuf",
        "Puppy", 
        "Zip",
        "IDZSwiftCommonCrypto"
      ],
      exclude: [
        "Data/Cache/Protobuf/Definitions/",
        "Data/Cache/Protobuf/CompileProtobuf.sh"
      ]),
    .target(
      name: "DeltaCoreC",
      publicHeadersPath: ".")
  ]
)
