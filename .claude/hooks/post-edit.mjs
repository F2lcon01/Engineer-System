#!/usr/bin/env node
// PostToolUse hook — fires after Edit/Write/MultiEdit.
// Tracks which files were modified in this session for /session-end.
// Self-rotates the log to avoid unbounded growth on long projects.

import { readFileSync, appendFileSync, statSync, renameSync, existsSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

const LOG_PATH = '.claude/.session-edits.log';
const MAX_BYTES = 256 * 1024;   // rotate at 256 KB

let raw = '';
try {
    raw = readFileSync(0, 'utf8');
} catch {
    process.exit(0);
}

let payload;
try {
    payload = JSON.parse(raw);
} catch {
    process.exit(0);
}

const filePath = payload?.tool_input?.file_path;
if (typeof filePath !== 'string' || filePath.length === 0) {
    process.exit(0);
}

const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
const line = `${timestamp} | ${filePath}\n`;

try {
    const dir = dirname(LOG_PATH);
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });

    if (existsSync(LOG_PATH)) {
        try {
            const { size } = statSync(LOG_PATH);
            if (size > MAX_BYTES) renameSync(LOG_PATH, `${LOG_PATH}.old`);
        } catch { /* tolerate race */ }
    }

    appendFileSync(LOG_PATH, line, 'utf8');
} catch {
    // Logging is best-effort. Never block the user's edit on log failure.
}

process.exit(0);
