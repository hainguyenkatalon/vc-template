#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT="$SCRIPT_DIR"
TEMPLATE_DIR="$REPO_ROOT/template"
PARENT_DIR=$(dirname "$REPO_ROOT")

usage() {
  cat <<'USAGE'
Usage: ./create_instance.sh <folder-name>

Creates a sibling folder populated with the template files (everything under
./template) while skipping README.md and this tool.

Arguments:
  folder-name          Name of the new directory to create next to this repo.
USAGE
}

if [[ $# -ne 1 ]]; then
  echo "Error: folder name required" >&2
  usage
  exit 1
fi

TARGET_NAME=$1

if [[ "$TARGET_NAME" == */* ]]; then
  echo "Error: folder name must not include '/' characters" >&2
  exit 1
fi

if [[ -z "$TARGET_NAME" ]]; then
  echo "Error: folder name cannot be empty" >&2
  exit 1
fi

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "Template directory not found at $TEMPLATE_DIR" >&2
  exit 1
fi

TARGET_PATH="$PARENT_DIR/$TARGET_NAME"

if [[ -e "$TARGET_PATH" ]]; then
  if [[ ! -d "$TARGET_PATH" ]]; then
    echo "Target path exists and is not a directory: $TARGET_PATH" >&2
    exit 1
  fi

  if [[ -n $(ls -A "$TARGET_PATH") ]]; then
    echo "Target directory already exists and is not empty: $TARGET_PATH" >&2
    exit 1
  fi
else
  mkdir -p "$TARGET_PATH"
fi

mkdir -p "$TARGET_PATH"
cp -a "$TEMPLATE_DIR/." "$TARGET_PATH/"

cat <<MSG
Template copied to $TARGET_PATH
You can now initialize a new git repo there (e.g., 'cd "$TARGET_PATH" && git init').
MSG
