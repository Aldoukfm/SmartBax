// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmartBax",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Mosquitto", from: "3.0.0")
        //.package(url: "https://github.com/aciidb0mb3r/SwiftMQTT", from: "3.0.0"),
        //.package(path: "/workspaces/SmartBax/SwiftMQTT")
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SmartBax",
            dependencies: ["SwiftyGPIO", "PerfectMosquitto"]),
        .testTarget(
            name: "SmartBaxTests",
            dependencies: ["SmartBax"]),
    ]
)
