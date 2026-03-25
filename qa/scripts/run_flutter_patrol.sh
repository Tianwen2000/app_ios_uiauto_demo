#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

load_qa_config
require_cmd patrol

if [[ -z "${QA_FLUTTER_PROJECT_DIR:-}" ]]; then
  echo "QA_FLUTTER_PROJECT_DIR is required for Patrol execution." >&2
  exit 1
fi

if [[ -z "${QA_DEVICE_UDID:-}" ]]; then
  echo "QA_DEVICE_UDID is required for real-device Patrol execution." >&2
  exit 1
fi

run_id="${QA_RUN_ID:-$("$SCRIPT_DIR/make_run_id.sh" flutter_patrol)}"
run_dir="$(make_run_dir "$run_id")"
log_file="$run_dir/logs/patrol.log"

pushd "$QA_FLUTTER_PROJECT_DIR" >/dev/null
env QA_RUN_ID="$run_id" \
  patrol test \
  --target "${QA_PATROL_TARGET:-test_driver/app.dart}" \
  --device "$QA_DEVICE_UDID" \
  --dart-define="QA_RUN_ID=$run_id" \
  --dart-define="QA_REPORTS_DIR=$run_dir" \
  --dart-define="QA_ARTIFACTS_DIR=$run_dir" | tee "$log_file"
popd >/dev/null
