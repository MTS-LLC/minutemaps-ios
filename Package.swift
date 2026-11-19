// swift-tools-version:5.9
import PackageDescription

// The MinuteMaps iOS SDK, as prebuilt binaries attached to this repo's releases:
//   • MinuteMaps.xcframework — the SDK (MTS-LLC/MinuteMaps-Mobile, iOS/MinuteMaps/)
//   • MobileCore.xcframework — the shared Kotlin Multiplatform core it is compiled against (MTS-LLC/MinuteMaps-Mobile,
//     mobile-core/)
// Both source repos are private, so SPM can't download their release assets; this public repo hosts them.
//
// The two always ship together under one tag: MinuteMaps only works with the MobileCore build it was compiled against.
// Don't edit `version` or the checksums by hand; scripts/release.sh sets them when it publishes a release.
let version = "1.7.0"
let minuteMapsChecksum = "acac0c7be5a4d6d0a3767ea5615d97bac9f13b29a3bcb740db9324e24f7494c6"
let mobileCoreChecksum = "a7f1de19f348e95fd6b53eefd87f1167a86af0dae4e9ebb14eb8b9c94db23272"

let releaseUrl = "https://github.com/MTS-LLC/minutemaps-ios/releases/download/\(version)"

let package = Package(
    name: "MinuteMaps",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "MinuteMaps", targets: ["MinuteMapsSupport"]),
    ],
    dependencies: [
        // MinuteMaps.xcframework is compiled against this version; keep the floor in step with MinuteMaps-Mobile's
        // iOS/MinuteMaps/MinuteMaps.xcodeproj Package.resolved.
        .package(url: "https://github.com/maplibre/maplibre-gl-native-distribution", from: "6.19.2"),
    ],
    targets: [
        .binaryTarget(
            name: "MinuteMaps",
            url: "\(releaseUrl)/MinuteMaps.xcframework.zip",
            checksum: minuteMapsChecksum
        ),
        .binaryTarget(
            name: "MobileCore",
            url: "\(releaseUrl)/MobileCore.xcframework.zip",
            checksum: mobileCoreChecksum
        ),
        // Binary targets can't declare dependencies, so this empty target is what ties the two frameworks and MapLibre
        // into the one `MinuteMaps` product. Apps import `MinuteMaps` and `MobileCore` directly, never this.
        .target(
            name: "MinuteMapsSupport",
            dependencies: [
                "MinuteMaps",
                "MobileCore",
                .product(name: "MapLibre", package: "maplibre-gl-native-distribution"),
            ]
        ),
    ]
)
