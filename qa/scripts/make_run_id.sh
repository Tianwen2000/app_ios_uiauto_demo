#!/usr/bin/env bash
set -euo pipefail

prefix="${1:-ios_ui}"
suffix="$(uuidgen | cut -d '-' -f 1 | tr '[:upper:]' '[:lower:]')"

printf '%s_%s_%s\n' "$prefix" "$(date '+%Y%m%d_%H%M%S')" "$suffix"
