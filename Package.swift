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
let version = "1.4.0"
let minuteMapsChecksum = "3344c9603c9a58dc2a760cf8a58c2a723f49334825fc3f35b8613282e27fe282"
let mobileCoreChecksum = "5c4c50b4ac9b558789a409ae5979e687209faa3a1ae8580c27dead78f22045d4"

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
