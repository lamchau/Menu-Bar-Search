// swift-tools-version:6.1
import PackageDescription

let package = Package(
  name: "menu",
  platforms: [.macOS(.v12)],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      from: "1.5.0"
    ),
    .package(
      url: "https://github.com/krisk/fuse-swift.git",
      from: "1.4.0"
    ),
  ],
  targets: [
    .target(
      name: "MenuBarLib",
      dependencies: [
        .product(name: "Fuse", package: "fuse-swift"),
      ],
      path: "source",
      exclude: ["CLI.swift"]
    ),
    .executableTarget(
      name: "menu",
      dependencies: [
        "MenuBarLib",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "cli",
      linkerSettings: [
        .unsafeFlags([
          "-Xlinker", "-sectcreate",
          "-Xlinker", "__TEXT",
          "-Xlinker", "__info_plist",
          "-Xlinker", "Info.plist",
        ])
      ]
    ),
    .testTarget(
      name: "MenuBarTests",
      dependencies: ["MenuBarLib"],
      path: "Tests"
    ),
  ]
)
