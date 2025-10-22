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

files=(
  "${spec_file}"
  "${journal_file}"
  "${todo_file}"
  "${scripts_readme}"
  "${progress_file}"
  "${technical_notes_file}"
  "${for_human_file}"
  "${wow_file}"
)

for f in "${files[@]}"; do
  if [[ ! -f "${f}" ]]; then
    # Create empty file without populating content
    : > "${f}"
    echo "Created ${f}"
  fi
done

echo "Spec scaffold ready at: ${spec_dir}"
