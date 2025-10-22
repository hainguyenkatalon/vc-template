#!/usr/bin/env bash
set -euo pipefail

REMOTE_RAW_URL=${REMOTE_RAW_URL:-"https://raw.githubusercontent.com/hainguyenkatalon/rnd_playwright_recorder_script/master/output/bundle.js"}
DEST="source/com.kms.katalon.core.webui/resources/extensions/scripts/smart-locator-bundle.js"

echo "Fetching smart-locator bundle from: $REMOTE_RAW_URL"
curl -fL "$REMOTE_RAW_URL" -o "$DEST"

BYTES=$(wc -c < "$DEST" | tr -d ' ')
SHA=$(shasum -a 256 "$DEST" | awk '{print $1}')

echo "Wrote $BYTES bytes to $DEST"
echo "SHA256: $SHA"

