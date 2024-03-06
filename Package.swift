// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Playdate",
    products: [
        .library(
            name: "Playdate",
            targets: ["Playdate"]),
        .library(
            name: "_CPlaydate",
            targets: ["_CPlaydate"]),
    ],
    targets: [
        .target(
            name: "Playdate",
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
            ]),
        .target(name: "_CPlaydate"),
    ]
)
