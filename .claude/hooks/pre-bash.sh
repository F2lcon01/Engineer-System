#!/bin/bash
# PreToolUse hook for Bash — blocks genuinely dangerous commands
# Exit 2 = block with reason; Exit 0 = allow

set -euo pipefail

INPUT=$(cat)

# Extract the command from the JSON input
COMMAND=$(echo "${INPUT}" | grep -oE '"command":[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command":[[:space:]]*"\([^"]*\)".*/\1/' || echo "")

# Patterns that are almost always destructive
DANGEROUS_PATTERNS=(
    'rm[[:space:]]+-rf?[[:space:]]+/'
    'rm[[:space:]]+-rf?[[:space:]]+~'
    'rm[[:space:]]+-rf?[[:space:]]+\*'
    ':\(\)\{.*\}'
    '>[[:space:]]*/dev/sda'
    'dd[[:space:]]+if=.*of=/dev/'
    'mkfs\.'
    'fdisk[[:space:]]+/dev/'
    'chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/'
    'shutdown[[:space:]]+-h[[:space:]]+now'
    'reboot[[:space:]]+now'
    'DROP[[:space:]]+DATABASE'
    'DROP[[:space:]]+TABLE'
    'git[[:space:]]+push[[:space:]]+(--force|-f)([[:space:]]|$)'
    'git[[:space:]]+push[[:space:]]+.*[[:space:]](--force|-f)([[:space:]]|$)'
    'git[[:space:]]+push[[:space:]]+--force-with-lease'
    'git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+HEAD~'
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if [[ "${COMMAND}" =~ ${pattern} ]]; then
        echo "🛑 BLOCKED: Dangerous command detected." >&2
        echo "Pattern matched: ${pattern}" >&2
        echo "Command: ${COMMAND}" >&2
        echo "" >&2
        echo "If this is intentional, the user must run it manually outside Claude Code." >&2
        exit 2
    fi
done

exit 0
