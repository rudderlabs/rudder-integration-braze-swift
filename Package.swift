// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RudderBraze",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "RudderBraze",
            targets: ["RudderBraze"]),
    ],
    dependencies: [
        .package(name: "Appboy-iOS-SDK", url: "https://github.com/Appboy/appboy-ios-sdk.git", "4.7.0"..<"5.0.0"),
        .package(name: "Rudder", url: "https://github.com/rudderlabs/rudder-sdk-ios", "2.2.4"..<"3.0.0")
    ],
    targets: [
        .target(
            name: "RudderBraze",
            dependencies: [
                .product(name: "AppboyKit", package: "Appboy-iOS-SDK"),
                .product(name: "Rudder", package: "Rudder"),
            ],
            path: "Sources"
        )
    ]
)
