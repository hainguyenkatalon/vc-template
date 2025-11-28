# AGENTS.md — Shared Way of Working

This guide stays repo-agnostic; humans own it and should edit it sparingly to keep it concise. Codex must not change this file unless explicitly requested.

This repo is the place where Codex keeps track of its work. Repos in `REPOS.md` is the actually place that Codex works on.

All files in this guide is relative to this repo.

## Spec files
- `REPOS.md` — human-maintained list of codebases (relative paths) where the agent is allowed to work.
- `SPEC.md` — requirements + acceptance (source of truth with code).
- `TECHNICAL_NOTES.md` — entry points, modules, paths, validation tips.
- `SPEC_PROGRESS.md` — high-level done vs remaining.
- `TODO.md` — thin-slice checklist.
- `TO_HUMAN.md` — blocking questions after exhausting safe workarounds.
- `WAY_OF_WORKING.md` — spec-specific cadence (builds/tests/validations).
- `USER_GUIDE.md` — user-facing value/usage/limits.

## Ownership and edit rules
- Human-maintained (Codex edits only on explicit request): `AGENTS.md`, `REPOS.md`, `SPEC.md`, and `WAY_OF_WORKING.md`.
- Agent-owned by default: the remaining spec docs (`TECHNICAL_NOTES.md`, `SPEC_PROGRESS.md`, `TODO.md`, `TO_HUMAN.md`, `USER_GUIDE.md`) plus code, config, tests, and automation scripts.

## Flow
1. **Stuck gate** — if `STUCK.md` exists next to your spec files, stop and summarize the block in `TO_HUMAN.md`.
2. **Load context** — read `SPEC.md`, `TECHNICAL_NOTES.md`, `SPEC_PROGRESS.md`, and `TODO.md` in the target repo to understand the current slice.
3. **Align docs** — compare each spec document with `SPEC.md` and the current code; update any stale information and log unanswered decisions in `TO_HUMAN.md`.
4. **Plan** — capture the next thin, reversible slice (with acceptance) in `TODO.md`, referencing `TECHNICAL_NOTES.md` for entry points.
5. **Implement** — keep edits minimal, precise, and scoped to the slice; update `TECHNICAL_NOTES.md` or automation scripts whenever behavior changes.
6. **Validate** — run fast checks first, then broader ones; prefer integration tests over stubs; collect evidence paths.
7. **User doc** — update `USER_GUIDE.md` to reflect the current value, access path, and limits.
8. **Commit & push** — keep commits focused on the completed slice.

## Code conventions
- Minimal, purpose-driven edits; avoid speculative churn.
- Preserve legacy behavior unless `SPEC.md` explicitly demands change.
- Each helper script must document usage in its README.
- Prefer fail-fast behavior; do not add fallback logic unless the spec explicitly requires it.

## Commit conventions
- Keep commits scoped to the completed slice.
- Ensure logs or build artifacts remain gitignored before committing.
