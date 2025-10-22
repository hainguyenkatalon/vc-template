# Tools and Commands (specs/tools)

This folder contains helper scripts for Codex (build and packaging helpers) that are reusable across branches.

Conventions
- Prefer explicit UTF‑8 encodings and deterministic outputs.
- Do not print secrets to stdout/stderr.
- Keep scripts self‑documenting (`-h/--help` when applicable).

Build Scripts Policy
- Treat these scripts as tested. If a build fails, analyze the error first; adjust environment/inputs.
- Only modify scripts with explicit human approval and record rationale in `specs/<branch>/JOURNAL.md`.

Environment & Build Commands
- JDK 17 and local Maven (`/opt/homebrew/bin/mvn`).
  - macOS/Homebrew env: `export JAVA_HOME=$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home; export PATH="$JAVA_HOME/bin:$PATH"`
- Repo‑wide helpers: `specs/tools/`
  - `build-studio-package.sh` — full product (CI‑parity) build
  - `fast-tycho-engine.sh` — incremental engine rebuild and hot‑patch (use `-m` to specify modules)
  - `spec-bootstrap.sh` — scaffold `specs/<branch>/` files

Command Patterns
- Full build: `specs/tools/build-studio-package.sh`
- Fast engine: `specs/tools/fast-tycho-engine.sh [-m mod1,mod2]`
- Scaffold spec: `specs/tools/spec-bootstrap.sh <branch>`

Codex Automation
- `specs/tools/codex-exec-loop.sh`
  - Runs Codex CLI in a short loop to drive incremental implementation for the current spec.
  - Stops on `specs/<branch>/STUCK.md` or after a max iteration count.
  - Options: `--prompt`, `--max`, `--branch`, `--codex-bin`, `--model`, `--max-lines`, `--max-chars`.
- `specs/tools/codex_tools.py`
  - Launches Codex CLI with sensible defaults, writes a log and structured output under `specs/<branch>/logs/`.
  - Flags: `-n/--iterations`, `--model`, `-o/--output`.

Docs Maintenance
- `specs/tools/todo-summarize-done-ai.sh` — summarize older Done items in `TODO.md`.
- `specs/tools/doc-refactor-ai.sh` — refactor a single doc/spec file in place.
- `specs/tools/spec-sweep-ai.sh` — sweep common spec files to keep them current.

Notes
- Some optional flows (e.g., `fast-tycho-engine.sh -r`) expect project‑specific runner scripts; provide your own if needed.
