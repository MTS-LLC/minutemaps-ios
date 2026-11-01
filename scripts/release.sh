#!/usr/bin/env bash
#
# Publishes a MinuteMaps release: points Package.swift at <version>, commits and tags it, and creates a GitHub
# release here carrying both binaries.
#
# Usage: scripts/release.sh <version> <artifacts-dir> [release notes]
#
#   <version>        plain semver, e.g. 1.0.0. Should match MARKETING_VERSION of the MinuteMaps target in MinuteMaps-Mobile.
#   <artifacts-dir>  the directory MinuteMaps-Mobile's iOS/MinuteMaps/scripts/build-xcframework.sh wrote
#                    (iOS/build/minutemaps-release), holding
#                    MinuteMaps.xcframework.zip and MobileCore.xcframework.zip.
#
# Refuses binaries that aren't this release's build: a MinuteMaps framework whose version isn't <version>, a MobileCore
# framework without a mobile-core release version, or zips identical to the ones the current release ships.
#
# Needs: a clean checkout of main, push access, and the gh CLI signed in.

set -euo pipefail

version="${1:-}"
artifacts="${2:-}"
notes="${3:-MinuteMaps $version}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || [ -z "$artifacts" ]; then
  echo "usage: $0 <version x.y.z> <artifacts-dir> [release notes]" >&2
  exit 1
fi

cd "$(dirname "$0")/.."

for zip in MinuteMaps MobileCore; do
  if [ ! -f "$artifacts/$zip.xcframework.zip" ]; then
    echo "error: $artifacts/$zip.xcframework.zip not found; run iOS/MinuteMaps/scripts/build-xcframework.sh in MinuteMaps-Mobile first" >&2
    exit 1
  fi
done
if [ "$(git branch --show-current)" != "main" ] || [ -n "$(git status --porcelain)" ]; then
  echo "error: run this from a clean checkout of main" >&2
  exit 1
fi
git fetch --tags --quiet origin
if git rev-parse -q --verify "refs/tags/$version" >/dev/null; then
  echo "error: tag $version already exists" >&2
  exit 1
fi

# The version each slice of <zip>'s framework reports (CFBundleShortVersionString), one per line.
slice_versions() {
  local zip="$1" name="$2" plist tmp
  tmp=$(mktemp)
  unzip -Z1 "$zip" | grep -E "^$name\.xcframework/[^/]+/$name\.framework/Info\.plist\$" | while read -r plist; do
    unzip -p "$zip" "$plist" > "$tmp"
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$tmp"
  done
  rm -f "$tmp"
}

# The binaries must be the build being released. 1.3.0 first went out carrying 1.2.2's zips, left over in the artifacts
# directory because build-xcframework.sh hadn't been rerun, and nothing here noticed.
minutemaps_versions=$(slice_versions "$artifacts/MinuteMaps.xcframework.zip" MinuteMaps | sort -u)
if [ "$minutemaps_versions" != "$version" ]; then
  echo "error: MinuteMaps.xcframework.zip is version $(echo $minutemaps_versions), not $version." >&2
  echo "  Rerun iOS/MinuteMaps/scripts/build-xcframework.sh <mobile-core version> in MinuteMaps-Mobile, on a checkout whose" >&2
  echo "  MARKETING_VERSION is $version; the artifacts directory may hold an earlier release's zips." >&2
  exit 1
fi
mobilecore_version=$(slice_versions "$artifacts/MobileCore.xcframework.zip" MobileCore | sort -u)
if [ -z "$mobilecore_version" ] || [ "$(echo "$mobilecore_version" | wc -l | tr -d ' ')" != 1 ]; then
  echo "error: MobileCore.xcframework.zip's slices disagree on their version: $(echo $mobilecore_version)" >&2
  exit 1
fi
# 1.0 is Kotlin/Native's default, from a build before mobile-core stamped its version; 0.1.0 is a build made without one.
if [ "$mobilecore_version" = "1.0" ] || [ "$mobilecore_version" = "0.1.0" ]; then
  echo "error: MobileCore.xcframework.zip is version $mobilecore_version, not a mobile-core release build." >&2
  echo "  Rerun build-xcframework.sh with the mobile-core version, e.g. build-xcframework.sh 0.6.0" >&2
  exit 1
fi

minutemaps_checksum=$(swift package compute-checksum "$artifacts/MinuteMaps.xcframework.zip")
mobilecore_checksum=$(swift package compute-checksum "$artifacts/MobileCore.xcframework.zip")

# Same bytes as the release Package.swift points at now: the previous release's binaries again.
for pair in "minuteMapsChecksum:$minutemaps_checksum:MinuteMaps" "mobileCoreChecksum:$mobilecore_checksum:MobileCore"; do
  IFS=: read -r key checksum zip <<< "$pair"
  if grep -q "^let $key = \"$checksum\"" Package.swift; then
    echo "error: $zip.xcframework.zip is identical to the one the current release ships; rebuild it" >&2
    exit 1
  fi
done

echo "Releasing MinuteMaps $version (MobileCore $mobilecore_version)"
echo "  MinuteMaps.xcframework.zip  $minutemaps_checksum"
echo "  MobileCore.xcframework.zip  $mobilecore_checksum"
read -r -p "Commit, tag, push and create the GitHub release? [y/N] " answer
[ "$answer" = "y" ] || { echo "Aborted."; exit 1; }

VERSION="$version" MM="$minutemaps_checksum" MC="$mobilecore_checksum" perl -pi -e '
  s/^let version = ".*"/let version = "$ENV{VERSION}"/;
  s/^let minuteMapsChecksum = ".*"/let minuteMapsChecksum = "$ENV{MM}"/;
  s/^let mobileCoreChecksum = ".*"/let mobileCoreChecksum = "$ENV{MC}"/;
' Package.swift

git diff --quiet || git commit -am "MinuteMaps $version"
git tag "$version"
git push origin main "$version"

gh release create "$version" \
  "$artifacts/MinuteMaps.xcframework.zip" \
  "$artifacts/MobileCore.xcframework.zip" \
  --title "MinuteMaps $version" \
  --notes "$notes"

echo "Published https://github.com/MTS-LLC/minutemaps-ios/releases/tag/$version"
