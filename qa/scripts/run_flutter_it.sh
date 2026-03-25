#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

load_qa_config
flutter_cmd="$(resolve_flutter_cmd)"

export QA_FLUTTER_PROJECT_DIR="${QA_FLUTTER_PROJECT_DIR:-$PROJECT_ROOT/flutter_client_demo}"
export QA_FLUTTER_DRIVER="${QA_FLUTTER_DRIVER:-test_driver/main.dart}"
export QA_FLUTTER_IT_TARGET="${QA_FLUTTER_IT_TARGET:-test_driver/app.dart}"
export QA_FLUTTER_TEST_CASES="${QA_FLUTTER_TEST_CASES:-testSmoke_LoginBrowseProfileLogout testSearchAndCategoryFilters}"
export QA_FLUTTER_CASE_RETRIES="${QA_FLUTTER_CASE_RETRIES:-2}"

run_id="${QA_RUN_ID:-$("$SCRIPT_DIR/make_run_id.sh" flutter_it)}"
run_dir="$(make_run_dir "$run_id")"
device_id="$(resolve_flutter_device)"

echo "Run ID: $run_id"
echo "Flutter device: $device_id"
echo "Reports: $run_dir"

printf '%s\n' "$run_id" > "$QA_ROOT/.current_flutter_it_run_id"

pushd "$QA_FLUTTER_PROJECT_DIR" >/dev/null
env LANG="$LANG" LC_ALL="$LC_ALL" LC_CTYPE="$LC_CTYPE" \
  "$flutter_cmd" pub get | tee "$run_dir/logs/flutter_pub_get.log"

if command -v pod >/dev/null 2>&1 && [[ -d "$QA_FLUTTER_PROJECT_DIR/ios" ]]; then
  pushd "$QA_FLUTTER_PROJECT_DIR/ios" >/dev/null
  env LANG="$LANG" LC_ALL="$LC_ALL" LC_CTYPE="$LC_CTYPE" pod install \
    | tee "$run_dir/logs/pod_install.log"
  popd >/dev/null
fi

read -r -a test_cases <<< "$QA_FLUTTER_TEST_CASES"
if [[ "${#test_cases[@]}" -eq 0 ]]; then
  echo "No QA_FLUTTER_TEST_CASES configured." >&2
  exit 1
fi

overall_status=0
for test_case in "${test_cases[@]}"; do
  case_status=1
  for (( attempt=1; attempt<=QA_FLUTTER_CASE_RETRIES; attempt++ )); do
    log_file="$run_dir/logs/${test_case}_attempt${attempt}_flutter_drive.log"
    echo "Running Flutter test case: $test_case (attempt $attempt/$QA_FLUTTER_CASE_RETRIES)"
    if command -v xcrun >/dev/null 2>&1 && [[ -n "${QA_APP_BUNDLE_ID:-}" ]]; then
      xcrun simctl terminate "$device_id" "$QA_APP_BUNDLE_ID" >/dev/null 2>&1 || true
      xcrun simctl uninstall "$device_id" "$QA_APP_BUNDLE_ID" >/dev/null 2>&1 || true
    fi
    if env QA_RUN_ID="$run_id" \
      QA_REPORTS_DIR="$run_dir" \
      QA_ARTIFACTS_DIR="$run_dir" \
      QA_TEST_CASE="$test_case" \
      LANG="$LANG" \
      LC_ALL="$LC_ALL" \
      LC_CTYPE="$LC_CTYPE" \
      "$flutter_cmd" drive \
      --no-pub \
      --driver "$QA_FLUTTER_DRIVER" \
      --target "$QA_FLUTTER_IT_TARGET" \
      -d "$device_id" \
      --dart-define="QA_RUN_ID=$run_id" \
      --dart-define="QA_TEST_USERNAME=${QA_TEST_USERNAME:-operator}" \
      --dart-define="QA_TEST_PASSWORD=${QA_TEST_PASSWORD:-123456}" | tee "$log_file"; then
      case_status=0
      break
    fi
  done
  if [[ "$case_status" -ne 0 ]]; then
    overall_status=1
  fi
done
popd >/dev/null

exit "$overall_status"
