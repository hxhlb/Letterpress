// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TRHud",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TRHud",
            targets: ["TRHud"]
        ),
        .library(
            name: "TRHudObjC",
            targets: ["TRHudObjC"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TRHudObjC",
            cSettings: [
                .headerSearchPath("headers"),
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
            ]
        ),
        .target(
            name: "TRHud",
            dependencies: ["TRHudObjC"]
        ),
        .testTarget(
            name: "TRHudTests",
            dependencies: ["TRHud"]
        ),
    ]
)
