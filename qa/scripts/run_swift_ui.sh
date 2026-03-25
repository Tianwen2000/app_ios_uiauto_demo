#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

load_qa_config
ensure_full_xcode_selected

if [[ -z "${QA_XCODE_SCHEME:-}" ]]; then
  echo "QA_XCODE_SCHEME is required." >&2
  exit 1
fi

run_id="${QA_RUN_ID:-$("$SCRIPT_DIR/make_run_id.sh" swift_ui)}"
run_dir="$(make_run_dir "$run_id")"
destination="$(resolve_destination)"
result_bundle="$run_dir/testing.xcresult"
log_file="$run_dir/logs/xcodebuild.log"

declare -a xcode_container_args=()
if [[ -n "${QA_XCODE_PROJECT:-}" ]]; then
  xcode_container_args=(-project "$QA_XCODE_PROJECT")
elif [[ -n "${QA_XCODE_WORKSPACE:-}" ]]; then
  xcode_container_args=(-workspace "$QA_XCODE_WORKSPACE")
else
  echo "Set QA_XCODE_PROJECT or QA_XCODE_WORKSPACE." >&2
  exit 1
fi

declare -a optional_args=()
if [[ -n "${QA_XCODE_TEST_PLAN:-}" ]]; then
  optional_args+=(-testPlan "$QA_XCODE_TEST_PLAN")
fi
if [[ -n "${QA_XCODE_ONLY_TESTING:-}" ]]; then
  optional_args+=(-only-testing "$QA_XCODE_ONLY_TESTING")
fi

echo "Run ID: $run_id"
echo "Destination: $destination"
echo "Reports: $run_dir"

printf '%s\n' "$run_id" > "$QA_ROOT/.current_swift_ui_run_id"

env QA_RUN_ID="$run_id" \
  QA_REPORTS_DIR="$run_dir" \
  QA_ARTIFACTS_DIR="$run_dir" \
  QA_TEST_USERNAME="${QA_TEST_USERNAME:-demo_operator}" \
  QA_TEST_PASSWORD="${QA_TEST_PASSWORD:-123456}" \
  xcodebuild test \
  "${xcode_container_args[@]}" \
  -scheme "$QA_XCODE_SCHEME" \
  -destination "$destination" \
  -derivedDataPath "$QA_DERIVED_DATA_PATH/$run_id" \
  -resultBundlePath "$result_bundle" \
  "${optional_args[@]}" | tee "$log_file"
