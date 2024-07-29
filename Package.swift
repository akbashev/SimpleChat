// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var package = Package(
  name: "swift-chat",
  platforms: [
    .macOS("14.0"),
    .iOS("17.0"),
  ],
  products: [
      .library(name: "App", targets: ["App"])
  ],
  dependencies: [
    // Apple
    .package(url: "https://github.com/akbashev/swift-distributed-actors.git", branch: "plugin_lifecycle_hook"),
    .package(url: "https://github.com/akbashev/cluster-event-sourcing.git", branch: "main"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.2.1"),
    .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-openapi-urlsession.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
    // Hummingbird
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0-beta.2"),
    .package(url: "https://github.com/swift-server/swift-openapi-hummingbird.git", from: "2.0.0-beta.1"),
    // Vapor
    .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.18.0"),
    // Pointfree.co
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.3.0"),
  ]
)

var targets: [PackageDescription.Target] = [
  .target(
    name: "API",
    dependencies: [
      .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
      .product(name: "OpenAPIHummingbird", package: "swift-openapi-hummingbird"),
      .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
    ],
    plugins: [
      .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
    ]
  ),
  .target(
    name: "App",
    dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      .product(name: "Dependencies", package: "swift-dependencies"),
      .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
      "API",
    ]
  ),
  .target(
    name: "Backend",
    dependencies: [
      "EventSource",
      "VirtualActor",
      .product(name: "DistributedCluster", package: "swift-distributed-actors")
    ]
  ),
  .target(
    name: "EventSource",
    dependencies: [
      .product(name: "EventSourcing", package: "cluster-event-sourcing"),
      .product(name: "DistributedCluster", package: "swift-distributed-actors"),
      .product(name: "PostgresNIO", package: "postgres-nio"),
    ]
  ),
  .target(
    name: "Persistence",
    dependencies: [
      .product(name: "DistributedCluster", package: "swift-distributed-actors"),
      .product(name: "PostgresNIO", package: "postgres-nio"),
    ]
  ),
  .target(
    name: "VirtualActor",
    dependencies: [
      .product(name: "DistributedCluster", package: "swift-distributed-actors"),
    ]
  ),
  .executableTarget(
    name: "Server",
    dependencies: [
      .product(name: "EventSourcing", package: "cluster-event-sourcing"),
      .product(name: "ArgumentParser", package: "swift-argument-parser"),
      .product(name: "Dependencies", package: "swift-dependencies"),
      .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
      "API",
      "Backend",
      "Persistence",
      "VirtualActor"
    ]
  ),
]

for target in targets {
  var settings = target.swiftSettings ?? []
  settings.append(.enableExperimentalFeature("StrictConcurrency"))
  target.swiftSettings = settings
}

package.targets = targets
