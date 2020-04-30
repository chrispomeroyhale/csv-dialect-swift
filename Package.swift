// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "csv-dialect-swift",
    products: [
        .library(name: "DialectalCSV", type: .static, targets: ["DialectalCSV"])
    ],
    dependencies: [],
    targets: [
        .target(name: "DialectalCSV", dependencies: [], path: "Sources"),
        .testTarget(name: "DialectalCSVTests", dependencies: ["DialectalCSV"])
    ],
    swiftLanguageVersions: [.version("4.2")]
)
