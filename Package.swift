// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "FileReader",
    products: [
        .library(name: "FileReader", targets: ["FileReader"]),
    ],
    targets: [
        .target(name: "FileReader", dependencies: []),
        .testTarget(name: "FileReaderTests", dependencies: ["FileReader"]),
    ]
)
