// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyExtensionLibrary",
    products: [
        .library(
            name: "MyExtensionLibrary",
            targets: ["MyExtensionLibrary"]),
    ],
    targets: [
        .target(
            name: "MyExtensionLibrary"),
    ]
)