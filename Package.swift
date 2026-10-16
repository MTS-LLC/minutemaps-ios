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
let version = "1.1.0"
let minuteMapsChecksum = "7bf84c949722555f59076a22e7c7489f8c61b921c5f9d9009d4265f16a9bc7c9"
let mobileCoreChecksum = "42036552e28b2c7073fd617aa55927fcbf50650499df6753822d61b684f1f5fe"

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
