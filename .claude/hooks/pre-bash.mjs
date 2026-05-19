#!/usr/bin/env node
// PreToolUse hook for Bash — blocks genuinely dangerous commands.
// Exit 2 = block (Claude sees stderr as feedback). Exit 0 = allow.
//
// v3.2 rewrite: parses tool input as real JSON (not regex on raw text),
// closing the v3.1 grep-bypass hole. Cross-platform: no shell required.

import { readFileSync } from 'node:fs';

// Read stdin (Claude Code pipes JSON tool input)
let raw = '';
try {
    raw = readFileSync(0, 'utf8');
} catch (err) {
    // Cannot read stdin — fail-open, do not block legitimate work
    process.exit(0);
}

let payload;
try {
    payload = JSON.parse(raw);
} catch {
    // Malformed payload — fail-open and let Claude Code's own validation handle it
    process.exit(0);
}

const command = payload?.tool_input?.command;
if (typeof command !== 'string' || command.length === 0) {
    process.exit(0);
}

// Normalize: collapse whitespace, lowercase for case-insensitive SQL-style matches.
// We keep the original `command` for the user-facing error message.
const normalized = command.replace(/\s+/g, ' ').trim();
const lower = normalized.toLowerCase();

// Pattern catalog. Each entry is { pattern, label, mode }.
// `mode: 'literal'` matches a JS RegExp on `normalized` (case-sensitive).
// `mode: 'ci'`      matches on `lower` (case-insensitive — for SQL etc).
const PATTERNS = [
    // Filesystem nukes
    { pattern: /\brm\s+(-[a-z]*r[a-z]*f|-[a-z]*f[a-z]*r)\s+(\/|~|\$HOME|\*)/, label: 'rm -rf on root / home / glob', mode: 'literal' },
    { pattern: /\brm\s+--no-preserve-root/, label: 'rm --no-preserve-root', mode: 'literal' },

    // Disk/partition destroyers
    { pattern: /\bmkfs(\.[a-z0-9]+)?\b/, label: 'mkfs (format filesystem)', mode: 'literal' },
    { pattern: /\bfdisk\s+\/dev\//, label: 'fdisk on block device', mode: 'literal' },
    { pattern: /\bdd\b[^|]*\bof=\/dev\//, label: 'dd writing to a block device', mode: 'literal' },
    { pattern: />\s*\/dev\/(sd[a-z]|nvme|hd[a-z]|mmcblk)/, label: 'redirect to raw block device', mode: 'literal' },

    // Permission/ownership wipes
    { pattern: /\bchmod\s+-R\s+(777|000)\s+\//, label: 'recursive chmod 777/000 at root', mode: 'literal' },
    { pattern: /\bchown\s+-R\s+[^\s]+\s+\//, label: 'recursive chown at root', mode: 'literal' },

    // Fork bombs / panic shutdowns
    { pattern: /:\s*\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:/, label: 'fork bomb', mode: 'literal' },
    { pattern: /\b(shutdown|halt|poweroff|reboot)\b\s+(-h\s+now|now|-r\s+now|\-P)/, label: 'immediate shutdown/reboot', mode: 'literal' },

    // Destructive git — push --force on protected branches
    { pattern: /\bgit\s+push\s+(\S+\s+)?(--force\b|--force-with-lease=?\S*|-f)\b/, label: 'git push --force (use --force-with-lease=ref:expect-only when truly needed)', mode: 'literal' },
    { pattern: /\bgit\s+reset\s+--hard\s+HEAD~/, label: 'git reset --hard HEAD~ (history rewrite)', mode: 'literal' },
    { pattern: /\bgit\s+(branch|tag)\s+-D\s+(main|master|release\/)/, label: 'force-delete protected branch/tag', mode: 'literal' },
    { pattern: /\bgit\s+clean\s+-[a-z]*[fx][a-z]*d?\s+\//, label: 'git clean at root', mode: 'literal' },

    // SQL nukes (case-insensitive)
    { pattern: /\bdrop\s+(database|schema|table)\b/, label: 'SQL DROP', mode: 'ci' },
    { pattern: /\btruncate\s+table\b/, label: 'SQL TRUNCATE TABLE', mode: 'ci' },

    // Container/k8s destructive
    { pattern: /\bdocker\s+system\s+prune\s+(--all|-a)\b/, label: 'docker system prune -a', mode: 'literal' },
    { pattern: /\bkubectl\s+delete\s+(ns|namespace|all)\b/, label: 'kubectl delete ns/all', mode: 'literal' },

    // Credential exfiltration / curl-pipe-sh
    { pattern: /\b(curl|wget)\s+[^|]+\|\s*(sudo\s+)?(bash|sh|zsh|pwsh|powershell)\b/, label: 'curl|wget piped into a shell', mode: 'literal' }
];

for (const { pattern, label, mode } of PATTERNS) {
    const target = mode === 'ci' ? lower : normalized;
    if (pattern.test(target)) {
        process.stderr.write([
            'BLOCKED: dangerous command detected.',
            `Reason : ${label}`,
            `Command: ${command}`,
            '',
            'If this is intentional, run it manually outside Claude Code.',
            'To unblock a false positive, edit .claude/hooks/pre-bash.mjs'
        ].join('\n') + '\n');
        process.exit(2);
    }
}

process.exit(0);
