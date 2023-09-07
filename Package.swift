// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    // Uncomment in order to perform complete concurrency checking
    // .enableExperimentalFeature("StrictConcurrency"),
    .enableExperimentalFeature("ExistentialAny"),
]

let package = Package(
    name: "CombineTraits",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AsynchronousOperation",
            targets: ["AsynchronousOperation"]),
        .library(
            name: "CombineTraits",
            targets: ["CombineTraits", "AsynchronousOperation", "CancelBag"]),
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
            dependencies: ["AsynchronousOperation", "CancelBag"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CombineTraitsTests",
            dependencies: ["CombineTraits", "AsynchronousOperation", "CancelBag", "CombineExpectations"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CombineTraitsAsynchronousOperationTests",
            dependencies: ["CombineTraits", "AsynchronousOperation", "CancelBag", "CombineExpectations"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CombineTraitsCancelBagTests",
            dependencies: ["CombineTraits", "AsynchronousOperation", "CancelBag"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CancelBag",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CancelBagTests",
            dependencies: ["CancelBag"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "AsynchronousOperation",
            swiftSettings: swiftSettings
        ),
    ]
)
