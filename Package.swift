// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TORoundedButton",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "TORoundedButton",
            type: .static,
            targets: ["TORoundedButton"]
        )
    ],
    targets: [
        .target(
            name: "TORoundedButton",
            sources: ["spm"]
        )
    ],
    cLanguageStandard: .c11
)
