# MinuteMaps iOS SDK

Swift package for the MinuteMaps iOS SDK: indoor maps, wayfinding and live navigation on MapLibre.

This repository only distributes prebuilt binaries. Each release carries `MinuteMaps.xcframework` and the
`MobileCore.xcframework` it was built against; `Package.swift` points at them.

## Installation

In Xcode, choose **File → Add Package Dependencies…**, enter

```
https://github.com/MTS-LLC/minutemaps-ios
```

and add the **MinuteMaps** product to your app target. In a `Package.swift`:

```swift
.package(url: "https://github.com/MTS-LLC/minutemaps-ios", from: "1.0.0")
// ...
.product(name: "MinuteMaps", package: "minutemaps-ios")
```

Then `import MinuteMaps` (and `import MobileCore` for the model types). The package brings in MapLibre Native; it needs
iOS 15.0 or later.

Releases 0.2.5–0.3.0 are the earlier MobileCore-only package (product `MobileCore`) and are kept for existing users.

## Documentation

The SDK's guide and API overview ship with its source, in the MinuteMaps iOS SDK repository
(`MinuteMaps/README.md`).

## Releasing

1. In MinuteMaps-Mobile, set the `MinuteMaps` target's `MARKETING_VERSION` (in `iOS/MinuteMaps/MinuteMaps.xcodeproj`)
   to the new version and run the script below, passing the mobile-core version to ship. It rebuilds MobileCore from
   that checkout's `mobile-core/`, so both zips come from the same commit:

   ```bash
   iOS/MinuteMaps/scripts/build-xcframework.sh <mobile-core version>
   ```

2. Here, on a clean `main`:

   ```bash
   scripts/release.sh <version> <path to MinuteMaps-Mobile>/iOS/build/minutemaps-release "Release notes"
   ```

   It writes the version and both checksums into `Package.swift`, commits, tags `<version>`, pushes, and creates the
   GitHub release with both zips attached.
