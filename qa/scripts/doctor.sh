#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

load_qa_config
ensure_full_xcode_selected
require_cmd xcrun

echo "Developer directory: $(xcode-select -p)"
xcodebuild -version

if [[ -n "${QA_DEVICE_UDID:-}" ]]; then
  if ! xcrun xctrace list devices 2>/dev/null | grep -Fq "$QA_DEVICE_UDID"; then
    echo "Configured device is not visible: $QA_DEVICE_UDID" >&2
    exit 1
  fi
  echo "Device detected: $QA_DEVICE_UDID"
fi

if [[ -n "${QA_FLUTTER_PROJECT_DIR:-}" ]]; then
  flutter_cmd="$(resolve_flutter_cmd)"
  echo "Flutter detected: $("$flutter_cmd" --version | head -n 1)"
fi

if [[ -n "${QA_PATROL_TARGET:-}" && -n "${QA_FLUTTER_PROJECT_DIR:-}" ]]; then
  if command -v patrol >/dev/null 2>&1; then
    echo "Patrol detected: $(patrol --version | head -n 1)"
  else
    echo "Patrol is optional and currently not installed."
  fi
fi
