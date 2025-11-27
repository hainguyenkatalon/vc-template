# JOURNAL

## 2025-11-17
### Pre
- Intent: bootstrap the `specs/main` scaffold so the AGENTS workflow has concrete files and paths before committing/pushing.
- Guardrails: only touch scaffolding/docs; no product code changes without an approved SPEC.
- Plan: (1) run `specs/tools/spec-bootstrap.sh`, (2) regenerate `SPEC_CONTEXT.md`, (3) document the missing SPEC requirements.

### Post
- Commands: `specs/tools/spec-bootstrap.sh`, `specs/tools/gen-spec-context.sh`.
- Outcome: spec scaffolding exists, `SPEC_CONTEXT.md` points to it, and doc placeholders/TODO/FOR_HUMAN capture the outstanding requirement.
- Next: wait for stakeholder requirements so SPEC.md and downstream docs can be populated.

## 2025-11-25
### Pre
- Intent: adjust `gen-spec-context.sh` so generated `SPEC_CONTEXT.md` drops template-only comments and better delineates recorded paths.
- Guardrails: limit edits to helper scripts/docs; keep generated outputs gitignored; avoid altering template placeholders.
- Plan: (1) review current `SPEC_CONTEXT.md.template` and generator behavior, (2) update script to strip header/add clear boundary, (3) refresh docs and regenerate the context file for verification.

### Post
- Commands: `apply_patch` updates to `SPEC_CONTEXT.md.template`, `specs/tools/gen-spec-context.sh`, `specs/tools/README.md`, `specs/SPEC_CONTEXT_GUIDE.md`; `specs/tools/gen-spec-context.sh` to regenerate `SPEC_CONTEXT.md`.
- Outcome: generator now uses the generic `<!-- @spec-context:start -->` marker to strip the template preamble and start output at the paths section; documentation notes the behavior; regenerated `SPEC_CONTEXT.md` reflects the trimmed format.
- Next: none; waiting for stakeholder requirements remains the standing task.
