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

run_dir="$QA_REPORTS_ROOT/$run_id"
if [[ ! -d "$run_dir" ]]; then
  echo "Run directory not found: $run_dir" >&2
  exit 1
fi

archive_path="$QA_REPORTS_ROOT/${run_id}.zip"
rm -f "$archive_path"

(
  cd "$QA_REPORTS_ROOT"
  zip -qry "$archive_path" "$run_id"
)

echo "Packed reports: $archive_path"
