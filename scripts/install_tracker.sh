#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
APK_DIR="$ROOT_DIR/apk"
IOS_WORKSPACE="$APP_DIR/ios/Runner.xcworkspace"
IOS_SIM_APP="$APP_DIR/build/ios/iphonesimulator/Runner.app"

print_help() {
  cat <<'EOF'
Tracker installer

Usage:
  ./scripts/install_tracker.sh android
  ./scripts/install_tracker.sh ios-sim
  ./scripts/install_tracker.sh ios-device
  ./scripts/install_tracker.sh help

Modes:
  android     Install the newest APK to a connected Android device using adb.
  ios-sim     Install the built iOS app to the currently booted iPhone simulator.
  ios-device  Open the Xcode workspace for manual install to a real iPhone.

Notes:
  - Android needs adb and a connected device with USB debugging enabled.
  - iOS simulator needs a booted simulator and a built Runner.app.
  - Real iPhone install still requires Apple signing in Xcode.
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

latest_apk() {
  find "$APK_DIR" -maxdepth 1 -type f -name 'tracker-v*.apk' | sort -V | tail -n 1
}

install_android() {
  require_cmd adb
  local apk_path
  apk_path="$(latest_apk)"
  if [[ -z "${apk_path:-}" || ! -f "$apk_path" ]]; then
    echo "No APK found in $APK_DIR"
    exit 1
  fi

  local device_count
  device_count="$(adb devices | awk 'NR>1 && $2=="device" {count++} END {print count+0}')"
  if [[ "$device_count" -eq 0 ]]; then
    echo "No Android device detected. Connect a phone and enable USB debugging."
    exit 1
  fi

  echo "Installing: $apk_path"
  adb install -r "$apk_path"
  echo "Android install finished."
}

install_ios_sim() {
  require_cmd xcrun
  if [[ ! -d "$IOS_SIM_APP" ]]; then
    echo "Simulator app not found at:"
    echo "  $IOS_SIM_APP"
    echo "Build it first with:"
    echo "  cd app && flutter build ios --simulator --no-codesign"
    exit 1
  fi

  local booted
  booted="$(xcrun simctl list devices booted | rg -o '[A-F0-9-]{36}' -m 1 || true)"
  if [[ -z "$booted" ]]; then
    echo "No booted iOS simulator found. Open Simulator and boot an iPhone first."
    exit 1
  fi

  echo "Installing Runner.app to simulator: $booted"
  xcrun simctl install "$booted" "$IOS_SIM_APP"
  xcrun simctl launch "$booted" com.fesaj.liquidSoapTracker || true
  echo "iOS simulator install finished."
}

install_ios_device() {
  if [[ ! -d "$IOS_WORKSPACE" ]]; then
    echo "Xcode workspace not found:"
    echo "  $IOS_WORKSPACE"
    exit 1
  fi

  echo "Opening Xcode workspace for real iPhone install..."
  open "$IOS_WORKSPACE"
  cat <<'EOF'

Next steps in Xcode:
1. Connect your iPhone.
2. Select the Runner target.
3. Open Signing & Capabilities.
4. Choose your Apple Team.
5. Select your iPhone as the run target.
6. Press Run.

Use the workspace, not the xcodeproj.
EOF
}

MODE="${1:-help}"

case "$MODE" in
  android)
    install_android
    ;;
  ios-sim)
    install_ios_sim
    ;;
  ios-device)
    install_ios_device
    ;;
  help|-h|--help)
    print_help
    ;;
  *)
    echo "Unknown mode: $MODE"
    echo
    print_help
    exit 1
    ;;
esac
