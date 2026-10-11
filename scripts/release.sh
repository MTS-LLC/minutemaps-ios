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

minutemaps_checksum=$(swift package compute-checksum "$artifacts/MinuteMaps.xcframework.zip")
mobilecore_checksum=$(swift package compute-checksum "$artifacts/MobileCore.xcframework.zip")

echo "Releasing MinuteMaps $version"
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
