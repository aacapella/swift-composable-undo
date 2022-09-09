// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-composable-undo",
  platforms: [.iOS(.v13)],
  products: [
    .library(
      name: "ComposableUndo",
      targets: ["ComposableUndo"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.40.1"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "ComposableUndo",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "DequeModule", package: "swift-collections")
      ]
    ),
    .testTarget(
      name: "ComposableUndoTests",
      dependencies: ["ComposableUndo"]
    ),
  ]
)
