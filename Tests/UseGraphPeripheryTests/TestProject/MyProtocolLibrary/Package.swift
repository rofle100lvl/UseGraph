// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyProtocolLibrary",
    products: [
        .library(
            name: "MyProtocolLibrary",
            targets: ["MyProtocolLibrary"]),
    ],
    targets: [
        .target(
            name: "MyProtocolLibrary"),
    ]
)