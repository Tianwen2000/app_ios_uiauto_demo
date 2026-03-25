#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

load_qa_config

run_id="${1:-${QA_RUN_ID:-}}"
if [[ -z "$run_id" ]]; then
  latest_run_dir="$(find_latest_run_dir)"
  if [[ -z "$latest_run_dir" ]]; then
    echo "No run_id supplied and no report directories found." >&2
    exit 1
  fi
  run_id="$(basename "$latest_run_dir")"
fi

run_dir="$(make_run_dir "$run_id")"
export_dir="$run_dir/exported"
mkdir -p "$export_dir"

if [[ -n "${QA_EXPORT_COMMAND:-}" ]]; then
  echo "Running custom export command for $run_id"
  env QA_RUN_ID="$run_id" QA_EXPORT_DESTINATION="$export_dir" bash -lc "$QA_EXPORT_COMMAND"
  exit 0
fi

if [[ -n "${QA_SIMULATOR_UDID:-}" ]]; then
  require_cmd xcrun

  bundle_id="${QA_EXPORT_CONTAINER_BUNDLE_ID:-${QA_APP_BUNDLE_ID:-}}"
  if [[ -z "$bundle_id" ]]; then
    echo "Set QA_EXPORT_CONTAINER_BUNDLE_ID or QA_APP_BUNDLE_ID for simulator export." >&2
    exit 1
  fi

  container_path="$(xcrun simctl get_app_container "$QA_SIMULATOR_UDID" "$bundle_id" data)"
  source_path="$container_path/${QA_EXPORT_RELATIVE_PATH:-Documents/qa_artifacts}/$run_id"

  if [[ ! -d "$source_path" ]]; then
    echo "Reports not found in simulator container: $source_path" >&2
    exit 1
  fi

  cp -R "$source_path" "$export_dir/"
  echo "Exported simulator reports to $export_dir"
  exit 0
fi

echo "Automatic real-device export is not enabled yet." >&2
echo "Set QA_EXPORT_COMMAND in qa/configs/devices.env after verifying the correct devicectl command on the target Mac." >&2
exit 1
