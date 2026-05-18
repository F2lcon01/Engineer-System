#!/bin/bash
# Stop hook — fires when Claude finishes a turn
# Reminds to run /session-end if files were edited but PROJECT_MAP wasn't touched

set -euo pipefail

TRACK_FILE=".claude/.session-edits.log"
PROJECT_MAP="memory/PROJECT_MAP.md"

# Only fire if files were edited this session
if [[ ! -f "${TRACK_FILE}" ]]; then
    exit 0
fi

EDITS_COUNT=$(wc -l < "${TRACK_FILE}" | tr -d ' ')
if [[ "${EDITS_COUNT}" -eq 0 ]]; then
    exit 0
fi

# Check if PROJECT_MAP was edited (it would appear in the track log)
if grep -q "${PROJECT_MAP}" "${TRACK_FILE}" 2>/dev/null; then
    # Already updated this session — clear log silently
    > "${TRACK_FILE}"
    exit 0
fi

# Files were edited but PROJECT_MAP wasn't — remind
echo "📝 Reminder: ${EDITS_COUNT} file edits this session, but PROJECT_MAP.md not updated." >&2
echo "Run /session-end to update the project memory before closing." >&2
exit 0
