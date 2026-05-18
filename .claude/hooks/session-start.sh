#!/bin/bash
# SessionStart hook — injects project context into Claude's session
# stdout becomes Claude's additional context (one of three events where this works)

set -euo pipefail

PROJECT_MAP="memory/PROJECT_MAP.md"
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M %Z')

echo "=== Session Context (injected by SessionStart hook) ==="
echo ""
echo "Current date/time: ${CURRENT_DATE}"
echo ""

if [[ -f "${PROJECT_MAP}" ]]; then
    echo "=== PROJECT_MAP.md contents ==="
    cat "${PROJECT_MAP}"
    echo ""
    echo "=== End PROJECT_MAP.md ==="
else
    echo "⚠️  PROJECT_MAP.md not found at ${PROJECT_MAP}"
    echo "First action: create it from the template before starting work."
fi

# Quick git context if in a repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo ""
    echo "=== Git context ==="
    echo "Branch: $(git branch --show-current 2>/dev/null || echo 'detached HEAD')"
    echo "Last commit: $(git log -1 --oneline 2>/dev/null || echo 'no commits')"
    UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    echo "Uncommitted changes: ${UNCOMMITTED} files"
fi

exit 0
