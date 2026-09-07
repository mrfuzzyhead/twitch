#!/bin/zsh

set -euo pipefail

project_dir="${0:A:h:h}"
app_dir="$project_dir/dist/Twitch.app"
contents_dir="$app_dir/Contents"
iconset_dir="$project_dir/.build/AppIcon.iconset"
icon_master="$project_dir/Resources/AppIcon-master.png"
expected_team_id="VD7DMST4GD"
default_signing_identity="Developer ID Application: Bradley Searle ($expected_team_id)"
signing_identity="${TWITCH_SIGNING_IDENTITY:-$default_signing_identity}"

if [[ "$signing_identity" == "-" ]]; then
    echo "error: TWITCH_SIGNING_IDENTITY must name a stable Apple Development or Developer ID Application identity." >&2
    echo "Ad-hoc signing is not allowed because it invalidates macOS privacy permissions after each rebuild." >&2
    exit 1
fi

available_identities="$(security find-identity -v -p codesigning)"
if [[ "$available_identities" != *"$signing_identity"* ]]; then
    echo "error: no valid code-signing identity matches TWITCH_SIGNING_IDENTITY=$signing_identity" >&2
    echo "Available identities:" >&2
    echo "$available_identities" >&2
    exit 1
fi

cd "$project_dir"
swift build -c release --product Twitch

mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources" "$iconset_dir"

sips -z 16 16 "$icon_master" --out "$iconset_dir/icon_16x16.png" >/dev/null
sips -z 32 32 "$icon_master" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$icon_master" --out "$iconset_dir/icon_32x32.png" >/dev/null
sips -z 64 64 "$icon_master" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$icon_master" --out "$iconset_dir/icon_128x128.png" >/dev/null
sips -z 256 256 "$icon_master" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$icon_master" --out "$iconset_dir/icon_256x256.png" >/dev/null
sips -z 512 512 "$icon_master" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$icon_master" --out "$iconset_dir/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$icon_master" --out "$iconset_dir/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$iconset_dir" -o "$contents_dir/Resources/AppIcon.icns"

cp "$project_dir/.build/release/Twitch" "$contents_dir/MacOS/Twitch"
cp "$project_dir/Support/Info.plist" "$contents_dir/Info.plist"

codesign --force --deep --options runtime --sign "$signing_identity" "$app_dir"
codesign --verify --deep --strict --verbose=2 "$app_dir"

signature_details="$(codesign -dvvv "$app_dir" 2>&1)"
if [[ "$signature_details" == *"Signature=adhoc"* || "$signature_details" != *"TeamIdentifier=$expected_team_id"* ]]; then
    echo "error: packaged app is not signed by expected team $expected_team_id" >&2
    exit 1
fi

echo "$app_dir"
