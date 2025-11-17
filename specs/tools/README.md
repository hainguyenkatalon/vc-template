# Tools and Commands (specs/tools)

This folder contains generic helper scripts for Codex that are reusable across branches.

Conventions
- Prefer explicit UTF‑8 encodings and deterministic outputs.
- Do not print secrets to stdout/stderr.
- Keep scripts self‑documenting (`-h/--help` when applicable).

Included Helpers
- `spec-bootstrap.sh` — scaffold `specs/<branch>/` files according to AGENTS.md (creates empty files; no default content).
- `gen-spec-context.sh` — fill `SPEC_CONTEXT.md` from `SPEC_CONTEXT.md.template`, auto-detecting the branch (override with `SPEC_DIR_OVERRIDE`).
- `codex_tools.py` — launch Codex CLI with sensible defaults; write logs/structured output under `specs/<branch>/logs/`.

Command Patterns
- Scaffold spec: `specs/tools/spec-bootstrap.sh <branch>`
  - Creates the folder structure and empty files: `SPEC.md`, `JOURNAL.md`, `TODO.md`, `SPEC_PROGRESS.md`, `TECHNICAL_NOTES.md`, `FOR_HUMAN.md`, `WAY_OF_WORKING.md`, and `scripts/README.md`.
- Regenerate context: `SPEC_DIR_OVERRIDE="specs/custom" specs/tools/gen-spec-context.sh`
  - Writes `SPEC_CONTEXT.md` by replacing placeholders in the template; run from repo root when `SPEC_CONTEXT.md` is missing or stale.
- Run Codex helper: `python3 specs/tools/codex_tools.py -n 5 --output specs/<branch>/logs`

Extending This Folder
- Add your own project‑specific scripts (build, test, packaging) as needed.
- Document each new script’s usage and arguments in this README.
