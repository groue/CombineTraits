// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineTraits",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15"),
        .tvOS("13.0"),
        .watchOS("6.0"),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CombineTraits",
            targets: ["CombineTraits"]),
        .library(
            name: "CancelBag",
            targets: ["CancelBag"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/groue/CombineExpectations.git", from: "0.7.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CombineTraits",
            dependencies: ["AsynchronousOperation", "CancelBag"]),
        .testTarget(
            name: "CombineTraitsTests",
            dependencies: ["CombineTraits", "CombineExpectations"]),
        .testTarget(
            name: "CombineTraitsAsynchronousOperationTests",
            dependencies: ["CombineTraits", "CombineExpectations"]),
        .testTarget(
            name: "CombineTraitsCancelBagTests",
            dependencies: ["CombineTraits"]),
        .target(
            name: "CancelBag",
            dependencies: []),
        .testTarget(
            name: "CancelBagTests",
            dependencies: ["CancelBag"]),
        .target(
            name: "AsynchronousOperation",
            dependencies: []),
    ]
)
