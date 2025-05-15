// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MorningRadioWatch",
    platforms: [
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "MorningRadioWatch",
            targets: ["MorningRadioWatch"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "MorningRadioWatch",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "Sources"
        ),
    ]
) 