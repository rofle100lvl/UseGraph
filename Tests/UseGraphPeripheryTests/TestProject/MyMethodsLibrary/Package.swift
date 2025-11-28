// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyMethodsLibrary",
    products: [
        .library(
            name: "MyMethodsLibrary",
            targets: ["MyMethodsLibrary"]),
    ],
    targets: [
        .target(
            name: "MyMethodsLibrary"),
    ]
)