// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BankaiCore",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BankaiCore",
            targets: ["BankaiCore"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "1.0.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BankaiCore",
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .enableExperimentalFeature("StrictConcurrency", .when(platforms: []))
            ]
//            dependencies: ["CombineSchedulers"]
        ),
        .testTarget(
            name: "BankaiCoreTests",
            dependencies: ["BankaiCore"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .enableExperimentalFeature("StrictConcurrency", .when(platforms: []))
            ]
        ),
    ]
)
