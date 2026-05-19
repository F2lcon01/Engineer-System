#!/usr/bin/env node
// Stop hook — fires when Claude finishes a turn.
// Reminds the user to run /session-end if files were edited but PROJECT_MAP wasn't touched.
// stderr is shown to the user as a transient notice (Stop hook does not block).

import { readFileSync, existsSync, writeFileSync } from 'node:fs';

const LOG_PATH = '.claude/.session-edits.log';
const PROJECT_MAP = 'memory/PROJECT_MAP.md';

if (!existsSync(LOG_PATH)) process.exit(0);

let lines = [];
try {
    lines = readFileSync(LOG_PATH, 'utf8').split('\n').filter(Boolean);
} catch {
    process.exit(0);
}

if (lines.length === 0) process.exit(0);

// If PROJECT_MAP was already updated this session, clear the log and stay quiet.
const projectMapTouched = lines.some(line => line.includes(PROJECT_MAP));
if (projectMapTouched) {
    try { writeFileSync(LOG_PATH, '', 'utf8'); } catch { /* tolerate */ }
    process.exit(0);
}

// Count unique files for a more useful reminder.
const uniqueFiles = new Set(
    lines.map(line => line.split('|').slice(1).join('|').trim()).filter(Boolean)
);

process.stderr.write([
    `Reminder: ${lines.length} edit event(s) across ${uniqueFiles.size} file(s) this session,`,
    `but ${PROJECT_MAP} was not updated.`,
    'Run /session-end to record the work before closing.'
].join('\n') + '\n');

process.exit(0);
