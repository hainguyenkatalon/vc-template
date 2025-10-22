#!/usr/bin/env bash
set -euo pipefail

# Scaffold specs/<branch>/ with SPEC.md, JOURNAL.md, TODO.md, and scripts/

branch="${1:-}"
if [[ -z "${branch}" ]]; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi
if [[ -z "${branch}" || "${branch}" == "HEAD" ]]; then
  echo "Unable to determine branch. Pass it explicitly: $0 <branch>" >&2
  exit 1
fi

root_dir="$(cd "$(dirname "$0")/../.." && pwd)"
spec_dir="${root_dir}/specs/${branch}"
scripts_dir="${spec_dir}/scripts"

mkdir -p "${scripts_dir}"

spec_file="${spec_dir}/SPEC.md"
journal_file="${spec_dir}/JOURNAL.md"
todo_file="${spec_dir}/TODO.md"
scripts_readme="${scripts_dir}/README.md"
progress_file="${spec_dir}/SPEC_PROGRESS.md"
technical_notes_file="${spec_dir}/TECHNICAL_NOTES.md"
for_human_file="${spec_dir}/FOR_HUMAN.md"
wow_file="${spec_dir}/WAY_OF_WORKING.md"

if [[ ! -f "${spec_file}" ]]; then
  cat > "${spec_file}" <<EOF
# Spec for branch: ${branch}

Status: draft

Scope
- Describe the goal and acceptance here.

Acceptance
- Bullet the observable acceptance criteria here.

Links
- Journal: JOURNAL.md
- TODO: TODO.md
EOF
  echo "Created ${spec_file}"
fi

if [[ ! -f "${journal_file}" ]]; then
  ts=$(date '+%Y-%m-%d %H:%M %Z')
  cat > "${journal_file}" <<EOF
${ts}
Intent: Initialize spec folder for branch ${branch}.
Guardrails: Minimal scaffold only; no behavior change.
Actions: Created SPEC.md, TODO.md, scripts/README.md.
Next: Fill SPEC.md acceptance; add first TODO slice.
EOF
  echo "Created ${journal_file}"
fi

if [[ ! -f "${todo_file}" ]]; then
  cat > "${todo_file}" <<'EOF'
- [ ] Define the next thin slice with acceptance
- [ ] Implement the slice
- [ ] Validate quickly (fail‑fast), journal outcomes
- [ ] Check off done and add follow‑ups
EOF
  echo "Created ${todo_file}"
fi

if [[ ! -f "${scripts_readme}" ]]; then
  cat > "${scripts_readme}" <<'EOF'
# Spec Scripts

Place spec‑specific helper scripts here. Each script should:
- Be self‑documenting (`-h/--help` if applicable)
- Avoid secrets in logs
- Prefer explicit UTF‑8 encodings
EOF
  echo "Created ${scripts_readme}"
fi

if [[ ! -f "${progress_file}" ]]; then
  cat > "${progress_file}" <<'EOF'
# Spec Progress

What’s done (high‑level, according to SPEC):
- 

What remains (high‑level):
- 
EOF
  echo "Created ${progress_file}"
fi

if [[ ! -f "${technical_notes_file}" ]]; then
  cat > "${technical_notes_file}" <<'EOF'
Technical notes

Purpose
- Map classes/modules, entry points, resources, config, and validation tips.

Populate this file with concrete file paths and method names as you implement.
EOF
  echo "Created ${technical_notes_file}"
fi

if [[ ! -f "${for_human_file}" ]]; then
  cat > "${for_human_file}" <<'EOF'
FOR_HUMAN — Questions/decisions for humans

Usage
- The agent writes here only when a human decision is required and no safe workaround remains.
- Keep entries short (context, decision needed, options, recommendation, why blocked).
EOF
  echo "Created ${for_human_file}"
fi

if [[ ! -f "${wow_file}" ]]; then
  cat > "${wow_file}" <<'EOF'
Way of Working — <branch>

Use this file to list spec‑specific iteration extras (build, tests, stubs, validations) to be run every cycle. Keep steps short and actionable.

Per‑Iteration (template)
- Stuck gate: stop if STUCK.md present; write questions to FOR_HUMAN.md.
- Pre‑flight: sync SPEC_PROGRESS vs SPEC; set keys; confirm BiDi/Smart Locator readiness.
- Implement: small slice; optionally use codex-exec-loop.sh.
- Validate: fast build or full build; run tests; capture evidence.
- Post: journal, progress, consolidate TODO; commit/push.
EOF
  echo "Created ${wow_file}"
fi

echo "Spec scaffold ready at: ${spec_dir}"
