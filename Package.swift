// swift-tools-version:5.0
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
            path: ".",
            sources: ["spm"]
        )
    ],
    cLanguageStandard: .c11
)
