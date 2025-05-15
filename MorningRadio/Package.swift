// swift-tools-version: 6.0.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MorningRadio",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MorningRadio",
            targets: ["MorningRadio"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SimonFairbairn/SwiftyMarkdown", from: "1.2.3"),
        .package(url: "https://github.com/maustinstar/shiny", branch: "master"),
        .package(url: "https://github.com/kylebshr/ScreenCorners", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MorningRadio",
            dependencies: [
                "SwiftyMarkdown",
                .product(name: "Shiny", package: "shiny"),
                "ScreenCorners"
            ],
            path: ".",
            exclude: [
                "Tests", 
                ".build", 
                ".swiftpm", 
                "Preview Content", 
                "MorningRadio.xcdatamodeld", 
                "Info.plist", 
                "MorningRadio.entitlements", 
                "Assets.xcassets",
                // Exclude Git-related files that cause conflicts
                ".git",
                "**/FETCH_HEAD",
                "**/HEAD",
                "**/config",
                "**/description",
                "**/hooks",
                "**/info",
                "**/master.priors",
                "**/output-file-map.json",
                "**/packed-refs",
                "**/sources",
                "**/repositories"
            ]),
        .testTarget(
            name: "MorningRadioTests",
            dependencies: ["MorningRadio"],
            path: "Tests/MorningRadioTests"),
    ]
)
