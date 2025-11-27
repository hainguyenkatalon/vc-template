#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE="$ROOT_DIR/SPEC_CONTEXT.md.template"
OUTPUT="$ROOT_DIR/SPEC_CONTEXT.md"
BRANCH="${SPEC_BRANCH:-$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)}"
SPEC_DIR="${SPEC_DIR_OVERRIDE:-specs/$BRANCH}"

if [[ ! -d "$ROOT_DIR/$SPEC_DIR" ]]; then
  echo "Spec folder not found: $SPEC_DIR" >&2
  echo "Set SPEC_DIR_OVERRIDE=<relative path> if needed" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Template missing: $TEMPLATE" >&2
  exit 1
fi

# Normalize path separators
normalize() {
  python3 - "$1" <<'PY'
import os, sys
print(sys.argv[1].replace('\\\\', '/'))
PY
}

VALUES=(
  "{{SPEC_DIR}}|$(normalize "$SPEC_DIR")"
  "{{SPEC}}|$(normalize "$SPEC_DIR/SPEC.md")"
  "{{TECHNICAL_NOTES}}|$(normalize "$SPEC_DIR/TECHNICAL_NOTES.md")"
  "{{SPEC_PROGRESS}}|$(normalize "$SPEC_DIR/SPEC_PROGRESS.md")"
  "{{TODO}}|$(normalize "$SPEC_DIR/TODO.md")"
  "{{JOURNAL}}|$(normalize "$SPEC_DIR/JOURNAL.md")"
  "{{FOR_HUMAN}}|$(normalize "$SPEC_DIR/FOR_HUMAN.md")"
  "{{WAY_OF_WORKING}}|$(normalize "$SPEC_DIR/WAY_OF_WORKING.md")"
  "{{USER_GUIDE}}|$(normalize "$SPEC_DIR/USER_GUIDE.md")"
  "{{SCRIPTS_DIR}}|$(normalize "$SPEC_DIR/scripts")"
)

content="$(cat "$TEMPLATE")"
for entry in "${VALUES[@]}"; do
  key="${entry%%|*}"
  val="${entry#*|}"
  content="${content//$key/$val}"
done

CUTOFF_MARKER="<!-- @spec-context:start -->"

if printf '%s\n' "$content" | grep -qF "$CUTOFF_MARKER"; then
  # Drop any template-only preamble so the generated file starts after the cutoff marker.
  content="$(printf '%s\n' "$content" | awk -v m="$CUTOFF_MARKER" 'BEGIN{keep=0} $0==m{keep=1; next} keep')"
fi

echo "$content" > "$OUTPUT"
echo "Wrote $OUTPUT using $SPEC_DIR"
