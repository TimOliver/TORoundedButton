// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TORoundedButton",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "TORoundedButton",
            targets: ["TORoundedButton"]
        )
    ],
    targets: [
        .target(
            name: "TORoundedButton",
            path: "TORoundedButton",
            exclude: [
                "TORoundedButtonExample",
                "TORoundedButtonExampleTest",
                "TORoundedButtonFramework"
            ],
            publicHeadersPath: "include"
        )
    ]
)
