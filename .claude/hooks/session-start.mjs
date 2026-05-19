#!/usr/bin/env node
// SessionStart hook — injects project context into Claude's session.
// stdout becomes Claude's additional context (only SessionStart, UserPromptSubmit, UserPromptExpansion behave this way).
// Cross-platform, no shell required. Requires Node 18+ (shipped with Claude Code).

import { readFileSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { resolve } from 'node:path';

const cwd = process.cwd();
const projectMap = resolve(cwd, 'memory', 'PROJECT_MAP.md');

const now = new Date();
const stamp = now.toISOString().replace('T', ' ').slice(0, 16);

const out = [];
out.push('=== Session Context (injected by SessionStart hook) ===');
out.push('');
out.push(`Current date/time: ${stamp} UTC`);
out.push('');

if (existsSync(projectMap)) {
    try {
        const content = readFileSync(projectMap, 'utf8');
        out.push('=== PROJECT_MAP.md contents ===');
        out.push(content.trimEnd());
        out.push('=== End PROJECT_MAP.md ===');
    } catch (err) {
        out.push(`PROJECT_MAP.md exists but could not be read: ${err.message}`);
    }
} else {
    out.push('PROJECT_MAP.md not found at memory/PROJECT_MAP.md');
    out.push('First action: create it from the template before starting work.');
}

// Best-effort git context. Never let git failure abort the hook.
const tryGit = (args) => {
    try {
        return execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    } catch {
        return null;
    }
};

const gitDir = tryGit(['rev-parse', '--git-dir']);
if (gitDir) {
    const branch = tryGit(['branch', '--show-current']) || 'detached HEAD';
    const lastCommit = tryGit(['log', '-1', '--oneline']) || 'no commits';
    const porcelain = tryGit(['status', '--porcelain']) || '';
    const uncommitted = porcelain ? porcelain.split('\n').filter(Boolean).length : 0;

    out.push('');
    out.push('=== Git context ===');
    out.push(`Branch: ${branch}`);
    out.push(`Last commit: ${lastCommit}`);
    out.push(`Uncommitted changes: ${uncommitted} files`);
}

process.stdout.write(out.join('\n') + '\n');
process.exit(0);
