---
name: git-conventions
description: Git commit message + branching conventions. Loaded when writing commit messages, opening PRs, or designing a branching strategy. Defaults to Conventional Commits but recognizes Angular, gitmoji, and free-form styles based on project history.
---

# Git Conventions Skill

Activates when writing a commit message, naming a branch, or designing a workflow. Read **before** writing any commit.

## Detect the project's style first

Run `git log --oneline -30` and look at the dominant pattern:

| Pattern observed | Style |
|------------------|-------|
| `feat: ...`, `fix: ...`, `chore: ...` | **Conventional Commits** |
| `feat(scope): ...`, `fix(scope): ...` | **Angular** (Conventional + scope) |
| `:sparkles: ...`, `:bug: ...` | **gitmoji** |
| Free-form sentences, no prefix | **Free-form** — match tone, no convention |
| Mixed/inconsistent | Propose adopting Conventional Commits going forward |

**Never impose Conventional Commits on a project that's using something else.** Match the existing style.

## Conventional Commits — the canonical rules

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | When |
|------|------|
| `feat` | New feature for the user |
| `fix` | Bug fix for the user |
| `docs` | Documentation only |
| `style` | Formatting; no code change |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding/correcting tests |
| `chore` | Build, tooling, deps; no production code change |
| `ci` | CI config changes |
| `revert` | Reverts a previous commit |

### Breaking change

```text
feat!: drop support for Node 14

BREAKING CHANGE: minimum Node version is now 18.
```

The `!` and the `BREAKING CHANGE:` footer are both required for tooling (semantic-release etc.) to bump the major version.

### Examples (good)

```text
feat(auth): add refresh-token rotation
fix(parser): handle CRLF in multi-line strings
docs: explain CLAUDE.local.md split in README
chore(deps): bump vitest from 1.6 to 2.0
test(cart): cover negative-price edge case
```

### Examples (bad — and why)

| Bad | Why |
|-----|-----|
| `update stuff` | What stuff? What changed? No type. |
| `fixed bug` | Past tense + vague. Use `fix: <what>` in imperative. |
| `feat: WIP` | WIP doesn't belong in main history — squash before merging |
| `fix: ; lint; refactor; tests;` | One commit per logical change; split this |
| `feat: added new feature called UserService...` (50 words on subject line) | Subject ≤ 72 chars; details go in body |

## Subject line rules

- ≤ 72 characters
- Imperative mood: "add", not "added" or "adds"
- No period at the end
- Lowercase after the colon (most projects)

## Body rules (when to write one)

Write a body when:

- The change is non-obvious from the diff
- The "why" matters more than the "what"
- The PR/issue context is needed for future reviewers

```text
fix(api): retry on 503 with exponential backoff

The upstream payment provider returns 503 during nightly maintenance.
Without retry, our checkout fails for 5-10 minutes once per day.

Retry policy: 3 attempts, base 1s, factor 2.
```

## Footers

```text
Co-authored-by: Name <email>
Refs: #123
Closes: #456
Reviewed-by: Name <email>
BREAKING CHANGE: <description>
```

## Branch naming

Project-dependent. Common patterns:

| Pattern | Example | When |
|---------|---------|------|
| `feature/<short-desc>` | `feature/refresh-tokens` | Most projects |
| `fix/<issue-number>-desc` | `fix/123-crlf-parser` | When tracking issues |
| `<initials>/<desc>` | `fk/refresh-tokens` | Small teams |
| `release/<version>` | `release/3.4.0` | Release branches |

Detect by `git branch -a | head -20` and match the dominant pattern.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| 30 commits with `WIP` then a force-push | Squash interactively before opening PR |
| `chore: update` (5 times in a row) | Be specific: `chore(deps): bump react to 19.0.0` |
| Commit message in past tense | Use imperative — "fix bug" not "fixed bug" |
| Mixing logical changes in one commit | Split — `git add -p` + multiple commits |
| Subject line > 72 chars | Move detail to body |
| No body on a non-obvious change | Add the WHY |

## Tools worth installing (project-dependent)

| Tool | Why |
|------|-----|
| `commitlint` | Enforce Conventional Commits in CI |
| `husky` (Node) or `pre-commit` (Python) | Run commitlint as git hook |
| `cz-cli` (commitizen) | Interactive commit prompt for newcomers |
| `semantic-release` | Auto-version + auto-changelog from Conventional Commits |

## When NOT to enforce conventions

- One-off scripts, throwaway repos → conventions are overhead
- Solo projects you'll never share → match your own existing style
- Projects mid-rewrite → wait until the dust settles, then standardize
