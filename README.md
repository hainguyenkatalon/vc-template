VC Template — Codex Working System

This folder contains a generic working style scaffold for agent-driven development:
- `AGENTS.md` — repo-agnostic execution flow and conventions (human-owned; edit sparingly).
- `REPOS.md` — human-maintained list of codebases (relative paths) where the agent is allowed to work.

All other spec files (`SPEC.md`, `TECHNICAL_NOTES.md`, `SPEC_PROGRESS.md`, `TODO.md`, `TO_HUMAN.md`, `WAY_OF_WORKING.md`, `USER_GUIDE.md`) start empty; humans typically populate `SPEC.md`, `WAY_OF_WORKING.md`, and `REPOS.md` first on a new branch.

In actual working repos, the style is layered: repo-agnostic (`AGENTS.md`), repo-specific (`REPO_WAY_OF_WORKING.md`), and branch-specific (`WAY_OF_WORKING.md` in each working repo). Spec documents such as `SPEC.md`, `TODO.md`, `TO_HUMAN.md`, and `USER_GUIDE.md` typically live at the root of each working repo rather than under a `specs/` folder.
