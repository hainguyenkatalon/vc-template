# AGENTS.md — Shared Way of Working

This guide stays repo-agnostic. Branch-specific expectations live in the active spec folder (`WAY_OF_WORKING.md`).

## Spec files
- `SPEC_CONTEXT.md` — canonical list of spec file paths. Generate it via `specs/SPEC_CONTEXT_GUIDE.md` when missing.
- `SPEC.md` — requirements + acceptance (source of truth with code).
- `TECHNICAL_NOTES.md` — entry points, modules, paths, validation tips.
- `SPEC_PROGRESS.md` — high-level done vs remaining.
- `TODO.md` — thin-slice checklist.
- `JOURNAL.md` — dated intent / commands / outcomes / next.
- `FOR_HUMAN.md` — blocking questions after exhausting safe workarounds.
- `WAY_OF_WORKING.md` — spec-specific cadence (builds/tests/validations).
- `USER_GUIDE.md` — user-facing value/usage/limits.
- `scripts/` — helper scripts (each must include a README entry).

## Spec context file
- `SPEC_CONTEXT.md` (gitignored) stores the exact relative paths for all spec documents. If it’s missing, read `specs/SPEC_CONTEXT_GUIDE.md` and run the helper script to regenerate it from the template.

## Flow
1. **Stuck gate** — if `$SPEC_DIR/STUCK.md` exists, stop and summarize the block in `FOR_HUMAN.md`.
2. **Load context** — read `SPEC_CONTEXT.md` (regenerate via `specs/SPEC_CONTEXT_GUIDE.md` if missing) so you have the exact file paths.
3. **Align docs** — compare each spec document with `SPEC.md` and the current code; update any stale information and log unanswered decisions in `FOR_HUMAN.md`.
4. **Plan** — capture the next thin, reversible slice (with acceptance) in `TODO.md`, referencing `TECHNICAL_NOTES.md` for entry points.
5. **Journal (pre)** — ensure the tree is clean; append intent/guardrails/plan to `JOURNAL.md`.
6. **Implement** — keep edits minimal, precise, and scoped to the slice; update `TECHNICAL_NOTES.md`, helper scripts, or their READMEs whenever behavior changes.
7. **Validate** — run fast checks first, then broader ones; prefer integration tests over stubs; collect evidence paths.
8. **Journal (post)** — append commands/artifacts/outcomes/next steps to `JOURNAL.md`; refresh `TODO.md`, `SPEC_PROGRESS.md`, and, if new questions remain, `FOR_HUMAN.md`.
9. **User doc** — update `USER_GUIDE.md` to reflect the current value, access path, and limits.
10. **Commit & push** — keep commits focused on the completed slice.

## Code conventions
- Minimal, purpose-driven edits; avoid speculative churn.
- Preserve legacy behavior unless `SPEC.md` explicitly demands change.
- Do not log secrets or sensitive tokens.
- Each helper inside `scripts/` must document usage in its README.
- Prefer fail-fast behavior; do not add fallback logic unless the spec explicitly requires it.

## Commit conventions
- Keep commits scoped to the completed slice.
- Ensure logs or build artifacts remain gitignored before committing.
