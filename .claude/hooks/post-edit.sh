#!/bin/bash
# PostToolUse hook — fires after Edit/Write/MultiEdit
# Tracks which files were modified in this session for /session-end

set -euo pipefail

TRACK_FILE=".claude/.session-edits.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Read the tool input from stdin (JSON)
INPUT=$(cat)

# Extract file path if present (best-effort, jq-free for portability)
FILE_PATH=$(echo "${INPUT}" | grep -oE '"file_path":[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path":[[:space:]]*"\([^"]*\)".*/\1/' || echo "")

if [[ -n "${FILE_PATH}" ]]; then
    echo "${TIMESTAMP} | ${FILE_PATH}" >> "${TRACK_FILE}"
fi

exit 0
