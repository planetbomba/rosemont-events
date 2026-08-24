#!/usr/bin/env bash
#
# Build → sign → notarize → staple → package the macOS app, end to end.
#
# `flutter build macos` produces an ad-hoc signed app, because the Xcode project
# sets CODE_SIGN_IDENTITY = "-" at the project level. This script replaces that
# signature inside-out (nested code first, app bundle last) with a Developer ID
# certificate and the hardened runtime, then notarizes and staples the result.
#
# Credentials never live in this file. Create a keychain profile once:
#
#   xcrun notarytool store-credentials "rosemont-notary" \
#     --apple-id you@example.com --team-id 23D3W8Y6ME --password <app-specific-password>
#
# (App-specific password from appleid.apple.com → Sign-In and Security.)
#
# Usage:
#   scripts/sign_macos.sh                    # build, sign, notarize, zip + dmg
#   scripts/sign_macos.sh --skip-build       # reuse the existing build
#   scripts/sign_macos.sh --no-notarize      # sign only (fast local check)
#   scripts/sign_macos.sh --no-dmg           # zip only, skip the disk image
#
# Environment:
#   NOTARY_PROFILE     keychain profile name   (default: rosemont-notary)
#   CODESIGN_IDENTITY  full certificate name   (default: autodetected)
#
set -euo pipefail

# Must match PRODUCT_NAME in macos/Runner/Configs/AppInfo.xcconfig.
# Contains a space, so every use below is quoted.
APP_NAME="Rosemont Events"
CONFIG="Release"
ENTITLEMENTS="macos/Runner/Release.entitlements"
DIST="dist"

NOTARY_PROFILE="${NOTARY_PROFILE:-rosemont-notary}"

SKIP_BUILD=0
DO_NOTARIZE=1
DO_DMG=1
for arg in "$@"; do
  case "$arg" in
    --skip-build)  SKIP_BUILD=1 ;;
    --no-notarize) DO_NOTARIZE=0 ;;
    --no-dmg)      DO_DMG=0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

cd "$(dirname "$0")/.."

APP="build/macos/Build/Products/${CONFIG}/${APP_NAME}.app"
VERSION=$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
ZIP="${DIST}/${APP_NAME} ${VERSION}.zip"
DMG="${DIST}/${APP_NAME} ${VERSION}.dmg"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- identity ---
# The Team ID is embedded in the certificate's common name, so nothing needs to
# be hardcoded here: "Developer ID Application: Jane Doe (AB12CD34EF)".
IDENTITY="${CODESIGN_IDENTITY:-}"
if [[ -z "$IDENTITY" ]]; then
  MATCHES=$(security find-identity -v -p codesigning | grep "Developer ID Application" || true)
  [[ -z "$MATCHES" ]] && fail "no 'Developer ID Application' certificate in your keychain.
  Create one at https://developer.apple.com/account/resources/certificates then
  download and double-click it, or set CODESIGN_IDENTITY explicitly."

  COUNT=$(printf '%s\n' "$MATCHES" | wc -l | tr -d ' ')
  if [[ "$COUNT" -gt 1 ]]; then
    printf '%s\n' "$MATCHES" >&2
    fail "found $COUNT Developer ID certificates; pick one via CODESIGN_IDENTITY=..."
  fi
  IDENTITY=$(printf '%s\n' "$MATCHES" | sed -E 's/.*"(.*)".*/\1/')
fi

TEAM_ID=$(printf '%s' "$IDENTITY" | sed -E 's/.*\(([A-Z0-9]+)\)$/\1/')
bold "Signing identity: $IDENTITY"
bold "Team ID:          $TEAM_ID"
bold "Version:          $VERSION"

[[ -f "$ENTITLEMENTS" ]] || fail "entitlements not found at $ENTITLEMENTS"

# Fail before the build rather than after it if credentials are missing.
if [[ "$DO_NOTARIZE" -eq 1 ]]; then
  bold "==> Checking notary credentials ('$NOTARY_PROFILE')"
  xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1 \
    || fail "keychain profile '$NOTARY_PROFILE' not usable (missing, or no network).
  Create it with:
    xcrun notarytool store-credentials \"$NOTARY_PROFILE\" \\
      --apple-id you@example.com --team-id $TEAM_ID --password <app-specific-password>
  Or re-run with --no-notarize."
fi

# ------------------------------------------------------------------- build ---
if [[ "$SKIP_BUILD" -eq 0 ]]; then
  bold "==> flutter build macos --release"
  flutter build macos --release
fi
[[ -d "$APP" ]] || fail "app bundle not found at $APP (drop --skip-build?)"

# -------------------------------------------------------------------- sign ---
# Order matters: codesign seals nested content by hash, so anything signed after
# its container invalidates that container's signature. Deepest items first.
# `--deep` would do this in one shot but Apple deprecated it — it applies the
# wrong entitlements to nested code.
sign() {
  codesign --force --timestamp --options runtime --sign "$IDENTITY" "$@"
}

bold "==> Signing nested frameworks and libraries"
if [[ -d "$APP/Contents/Frameworks" ]]; then
  while IFS= read -r -d '' item; do
    echo "    $(basename "$item")"
    sign "$item"
  done < <(find "$APP/Contents/Frameworks" -mindepth 1 -maxdepth 1 \
             \( -name "*.framework" -o -name "*.dylib" -o -name "*.app" \) -print0)
fi

while IFS= read -r -d '' item; do
  echo "    $(basename "$item")"
  sign "$item"
done < <(find "$APP/Contents" -type f \( -name "*.dylib" -o -name "*.so" \) \
           -not -path "*/Frameworks/*" -print0)

bold "==> Signing app bundle"
# Entitlements go on the app only — nested code inherits its own, not the app's.
codesign --force --timestamp --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --sign "$IDENTITY" "$APP"

# ------------------------------------------------------------------ verify ---
bold "==> Verifying signature"
codesign --verify --strict --verbose=2 "$APP"

bold "==> Hardened runtime / entitlements"
# Capture once into a variable rather than piping codesign into grep twice.
# Under `set -o pipefail`, a `grep -q` that exits on first match makes codesign
# die of SIGPIPE (141) and that status becomes the pipeline's — which silently
# inverted this check. Matching against a string avoids the pipe entirely.
SIGINFO=$(codesign --display --verbose=2 "$APP" 2>&1 || true)
# The hardened-runtime flag lives on the CodeDirectory line, not at line start.
grep -E "^(Identifier|Authority|TeamIdentifier|Timestamp)|CodeDirectory" <<<"$SIGINFO" || true
if [[ "$SIGINFO" == *"(runtime)"* ]]; then
  echo "hardened runtime: enabled"
else
  fail "hardened runtime NOT set — notarization would be rejected"
fi

# --------------------------------------------------------------- notarize ---
# Submits one artifact, waits, then staples the ticket into the target. The
# submitted zip is only a transport container; the ticket goes into the .app.
notarize() {
  local submit="$1" target="$2" out status id
  bold "==> Notarizing $(basename "$submit")"
  out=$(xcrun notarytool submit "$submit" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1) || true
  printf '%s\n' "$out"

  # Match only the indented "  status:" line, not "Current status: ...".
  # Single awk pass, no `| head`/`| tail` — those close the pipe early and can
  # SIGPIPE the upstream process, which `set -o pipefail` would turn into a
  # spurious failure.
  status=$(awk '/^[[:space:]]+status:/ {s=$2} END {print s}' <<<"$out")
  id=$(awk '/^[[:space:]]+id:/ {if (!seen) {print $2; seen=1}}' <<<"$out")

  if [[ "$status" != "Accepted" ]]; then
    # --wait reports the status but never the reason; the log has it.
    [[ -n "$id" ]] && xcrun notarytool log "$id" --keychain-profile "$NOTARY_PROFILE" || true
    fail "notarization failed for $(basename "$submit") (status: ${status:-unknown})"
  fi

  bold "==> Stapling $(basename "$target")"
  xcrun stapler staple "$target"
  xcrun stapler validate "$target"
}

mkdir -p "$DIST"

if [[ "$DO_NOTARIZE" -eq 1 ]]; then
  TMPZIP=$(mktemp -d)/"${APP_NAME}.zip"
  ditto -c -k --keepParent "$APP" "$TMPZIP"
  notarize "$TMPZIP" "$APP"
  rm -rf "$(dirname "$TMPZIP")"
fi

# ---------------------------------------------------------------- package ---
# Zipped AFTER stapling — the archive submitted above does not contain the
# ticket, so shipping it would leave users needing to reach Apple to launch.
bold "==> Packaging zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

if [[ "$DO_DMG" -eq 1 ]]; then
  bold "==> Packaging dmg"
  STAGE=$(mktemp -d)
  ditto "$APP" "$STAGE/${APP_NAME}.app"
  ln -s /Applications "$STAGE/Applications"

  rm -f "$DMG"
  hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" \
    -ov -format UDZO -quiet "$DMG"
  rm -rf "$STAGE"

  # A disk image is signed too, and gets its own notarization ticket so
  # Gatekeeper clears it before the user ever opens it.
  codesign --force --timestamp --sign "$IDENTITY" "$DMG"
  [[ "$DO_NOTARIZE" -eq 1 ]] && notarize "$DMG" "$DMG"
fi

# ----------------------------------------------------------------- summary ---
echo
bold "Done."
echo "  app: $APP"
[[ -f "$ZIP" ]] && echo "  zip: $ZIP"
[[ -f "$DMG" ]] && echo "  dmg: $DMG"
if [[ "$DO_NOTARIZE" -eq 0 ]]; then
  echo
  echo "NOT notarized (--no-notarize). Other Macs will warn on first launch."
else
  echo
  echo "Notarized and stapled. Verify a download behaves correctly with:"
  echo "  spctl --assess --type exec -vvv \"$APP\""
fi
