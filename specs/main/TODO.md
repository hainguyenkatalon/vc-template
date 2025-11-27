# TODO

## 2025-11-17
- [x] Bootstrap the spec scaffolding via `specs/tools/spec-bootstrap.sh` and regenerate `SPEC_CONTEXT.md` (acceptance: `specs/main/*` exists and helper script runs cleanly).
- [ ] Capture the actual product requirements so `SPEC.md` can guide implementation (blocked: awaiting stakeholder details; see `FOR_HUMAN.md`).

## 2025-11-25
- [x] Update `specs/tools/gen-spec-context.sh` so generated `SPEC_CONTEXT.md` omits template-only comments and clearly marks the boundary between template metadata and recorded paths (acceptance: running the script produces a comment-free output that starts with the paths section, and the helper docs mention the behavior; the cutoff is driven by the generic `<!-- @spec-context:start -->` marker).
