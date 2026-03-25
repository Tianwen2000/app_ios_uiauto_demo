#!/usr/bin/env bash
set -euo pipefail

QA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$QA_ROOT/.." && pwd)"
QA_CONFIG_FILE="${QA_CONFIG_FILE:-$QA_ROOT/configs/devices.env}"
QA_FALLBACK_CONFIG_FILE="$QA_ROOT/configs/devices.example.env"

load_qa_config() {
  if [[ -f "$QA_CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$QA_CONFIG_FILE"
  elif [[ -f "$QA_FALLBACK_CONFIG_FILE" ]]; then
    echo "devices.env not found, falling back to devices.example.env" >&2
    # shellcheck disable=SC1090
    source "$QA_FALLBACK_CONFIG_FILE"
  else
    echo "Missing qa/configs/devices.env" >&2
    exit 1
  fi

  export QA_ROOT PROJECT_ROOT
  export QA_REPORTS_ROOT="${QA_REPORTS_ROOT:-${QA_ARTIFACTS_ROOT:-$QA_ROOT/reports}}"
  export QA_ARTIFACTS_ROOT="$QA_REPORTS_ROOT"
  export QA_DERIVED_DATA_PATH="${QA_DERIVED_DATA_PATH:-$PROJECT_ROOT/.derived_data}"
  export QA_LOCALE="${QA_LOCALE:-en_US.UTF-8}"
  export LANG="$QA_LOCALE"
  export LC_ALL="$QA_LOCALE"
  export LC_CTYPE="$QA_LOCALE"
  mkdir -p "$QA_REPORTS_ROOT" "$QA_DERIVED_DATA_PATH"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

resolve_flutter_cmd() {
  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return
  fi

  if [[ -n "${QA_FLUTTER_BIN:-}" && -x "${QA_FLUTTER_BIN:-}" ]]; then
    printf '%s\n' "$QA_FLUTTER_BIN"
    return
  fi

  if [[ -x "$HOME/develop/flutter/bin/flutter" ]]; then
    printf '%s\n' "$HOME/develop/flutter/bin/flutter"
    return
  fi

  echo "Missing required command: flutter" >&2
  exit 1
}

ensure_full_xcode_selected() {
  require_cmd xcode-select

  local developer_dir
  developer_dir="$(xcode-select -p 2>/dev/null || true)"

  if [[ -z "$developer_dir" || "$developer_dir" == "/Library/Developer/CommandLineTools" ]]; then
    echo "Full Xcode is not selected." >&2
    echo "Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    exit 1
  fi

  if ! xcodebuild -version >/dev/null 2>&1; then
    echo "xcodebuild is unavailable under developer directory: $developer_dir" >&2
    exit 1
  fi
}

resolve_destination() {
  if [[ -n "${QA_DEVICE_UDID:-}" ]]; then
    printf 'platform=iOS,id=%s\n' "$QA_DEVICE_UDID"
    return
  fi

  if [[ -n "${QA_SIMULATOR_UDID:-}" ]]; then
    printf 'platform=iOS Simulator,id=%s\n' "$QA_SIMULATOR_UDID"
    return
  fi

  if [[ -n "${QA_SIMULATOR_NAME:-}" ]]; then
    printf 'platform=iOS Simulator,name=%s\n' "$QA_SIMULATOR_NAME"
    return
  fi

  printf 'platform=iOS Simulator,name=iPhone 15\n'
}

resolve_simulator_udid_by_name() {
  local simulator_name="$1"
  require_cmd xcrun
  require_cmd python3

  xcrun simctl list devices available -j | python3 -c '
import json
import sys

target = sys.argv[1]
payload = json.load(sys.stdin)
devices = payload.get("devices", {})

for runtime_devices in devices.values():
    for device in runtime_devices:
        if device.get("isAvailable") and device.get("name") == target:
            print(device["udid"])
            raise SystemExit(0)

raise SystemExit(1)
' "$simulator_name"
}

boot_simulator_if_needed() {
  local simulator_udid="$1"
  require_cmd xcrun

  open -a Simulator >/dev/null 2>&1 || true
  xcrun simctl boot "$simulator_udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$simulator_udid" -b >/dev/null
}

resolve_flutter_device() {
  if [[ -n "${QA_DEVICE_UDID:-}" ]]; then
    printf '%s\n' "$QA_DEVICE_UDID"
    return
  fi

  if [[ -n "${QA_SIMULATOR_UDID:-}" ]]; then
    boot_simulator_if_needed "$QA_SIMULATOR_UDID"
    printf '%s\n' "$QA_SIMULATOR_UDID"
    return
  fi

  if [[ -n "${QA_SIMULATOR_NAME:-}" ]]; then
    local simulator_udid
    simulator_udid="$(resolve_simulator_udid_by_name "$QA_SIMULATOR_NAME")"
    if [[ -z "$simulator_udid" ]]; then
      echo "Unable to resolve simulator UDID for: $QA_SIMULATOR_NAME" >&2
      exit 1
    fi
    boot_simulator_if_needed "$simulator_udid"
    printf '%s\n' "$simulator_udid"
    return
  fi

  printf 'macos\n'
}

make_run_dir() {
  local run_id="$1"
  local run_dir="$QA_REPORTS_ROOT/$run_id"
  mkdir -p "$run_dir" "$run_dir/logs"
  printf '%s\n' "$run_dir"
}

find_latest_run_dir() {
  find "$QA_REPORTS_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 |
    xargs -0 stat -f '%m %N' 2>/dev/null |
    sort -nr |
    head -n 1 |
    cut -d' ' -f2-
}
