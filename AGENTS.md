# AGENTS.md — Way of Working Steps

This file tells Codex how to locate the current spec and how to execute, step‑by‑step. Shared helper scripts live under `specs/tools/`.

## Steps (Codex flow)
0) Stuck gate
   - If `specs/<branch>/STUCK.md` exists, do not proceed with any edits. Inform the human that you are blocked and point them to `FOR_HUMAN.md` in the spec folder. Exit.
   - Clearing a stuck: a human removes `STUCK.md` (or renames it) after addressing the blocking items.
1) Detect branch
   - Run: `git rev-parse --abbrev-ref HEAD`.
2) Locate spec folder (Branch → Spec)
   - The current branch name defines the spec path: `specs/<branch>/`.
   - Examples: `feat/self-healing-llm` → `specs/feat/self-healing-llm/`; `fix/webui-timeouts` → `specs/fix/webui-timeouts/`.
   - If missing, scaffold the folder with this structure:
     - `SPEC.md` — requirements and acceptance. YOU ARE NOT SUPPOSED TO CHANGE THIS FILE.
     - `TECHNICAL_NOTES.md` — implementation map: classes/modules, entry points, resources, config and validation tips
     - `FOR_HUMAN.md` — running list of decisions/questions that need human input (agent must try all feasible workarounds before writing here)
     - `SPEC_PROGRESS.md` — high‑level progress against the spec (what is done/remaining; no low‑level details)
     - `JOURNAL.md` — dated entries (intent, guardrails, commands, outcomes, next)
     - `TODO.md` — short actionable list; update before/after work (check off done and add new items)
     - `WAY_OF_WORKING.md` — spec‑specific practices/conventions for this branch
     - `scripts/` — spec‑specific helpers with a `README.md` for usage
   - Common helpers live under `specs/tools/` with a `README.md`.
   - Source of truth: `SPEC.md` and the codebase are canonical. Other docs (`SPEC_PROGRESS.md`, `TODO.md`, `TECHNICAL_NOTES.md`, `JOURNAL.md`) can lag; when you find contradictions, update those docs to match the spec and current code.
3) Confirm environment & conventions
   - Skim `specs/tools/README.md` for JDK/Maven and command patterns.
   - Read this spec’s `WAY_OF_WORKING.md` and follow its per‑iteration extras (fast build, TI tests, validations).
4) Understand scope and slice
   - Ultimate source of truth: `SPEC.md` and the codebase. Use them to anchor decisions.
   - First, compare `SPEC_PROGRESS.md` against `SPEC.md` and the codebase to identify gaps. If any doc is stale or misleading, update it immediately (and journal):
     - `SPEC_PROGRESS.md` (high‑level status)
     - `TODO.md` (next actionable slices)
     - `TECHNICAL_NOTES.md` (entry points, classes, resources)
     - `WAY_OF_WORKING.md` (iteration extras)
     - `USER_GUIDE.md` (user‑facing usage/value/limits)
     - `scripts/README.md` (script usage)
     - `FOR_HUMAN.md` (open decisions)
   - Then, read `SPEC.md` (requirements) and `TECHNICAL_NOTES.md` (where to change code). Create/update `TODO.md` with the next thin, reversible slice.
   - Update `TODO.md` before starting and after finishing: check off done items and add new follow‑ups.
   - Keep legacy flows stable unless the spec changes them.
   - Human loop: If you hit a decision that requires human input, first attempt any safe, parallelizable tasks. If still blocked, append a concise entry to `FOR_HUMAN.md` and continue with other tasks. Only when nothing more can be done, create `STUCK.md` in the spec folder and stop work.
5) Journal (pre)
   - First of all, commit all changes in the codebase.
   - Add an entry to `JOURNAL.md`: intent, guardrails, immediate plan. Communicate actions with brief preambles.
6) Implement (canonical, fail‑fast)
   - Make minimal, precise changes; avoid large surface edits.
   - Honor design‑by‑contract: surface contract violations early (don’t mask errors).
   - Avoid hacks/ad‑hoc fixes and unnecessary fallbacks; prefer canonical, systematic solutions.
   - Use logging wisely to aid troubleshooting and trace flow (no secrets).
   - Any new script or tool must include a `README.md` section describing usage and arguments.
   - Do not reintroduce stub runner/server scripts (e.g., `run-fallback-stub.sh`, `stub-llm-server.js`, `test-stub-llm.sh`). Validate with integration flows only.

Build scripts policy
- The build scripts under `specs/tools/` are considered tested. If a build fails, do not blindly edit scripts.
- First, understand the error (logs/stacktrace, environment, inputs, credentials). Prefer fixing inputs/env.
- Only change build scripts with explicit human approval and after documenting rationale in `JOURNAL.md`.


7) Validate (quick → fail‑fast → broad)
   - Prefer quick, fail‑fast validation first (targeted/unit/integration). Defer full product builds until the end of a batch of changes.
   - Capture evidence paths (logs, reports) for the journal.
   - Always prefer integration tests over stub tests; stub tests guarantee nothing in complex systems and software. Use stubs only for local smoke checks and never as a replacement for integration validation.
8) Journal (post)
   - Record commands, artifacts/paths, outcomes, and next actions in `JOURNAL.md`.
   - Update `TODO.md`: check off completed items and add follow‑ups for the next slice.
   - No manual hygiene here; the loop script (`specs/tools/codex-exec-loop.sh`) will auto‑trigger AI sweeps if docs grow beyond limits.
9) User‑facing documentation
    - Update or add a short doc (for users/PM/QA) describing what function has been implemented, its value, how to access it, and known limitations (no internal design details).
10) Commit.

## Notes
- When updating *.md files, consolidate their content while still retaining useful information.

## Reference
- Tooling/Commands: `specs/tools/README.md`
- Branch technical map: `specs/<branch>/TECHNICAL_NOTES.md`
- Human loop files: `specs/<branch>/FOR_HUMAN.md` (questions) and `specs/<branch>/STUCK.md` (hard stop flag)

 
