#!/usr/bin/env bash
# Fetch Roblox's API dump and (optionally) convert it to a luau-lsp definitions file.
#
# Usage: ./tools/fetch_api_types.sh [api-dump.json]
#
# If an API dump path is given, this script is a placeholder for a future JSON -> .d.luau
# converter. Roblox mirrors rotate; update SOURCE_URL here when the official dump moves.
#
# Official dump: https://setup.rbxcdn.com/api_dump.json  (may require auth/region)
set -euo pipefail

cd "$(dirname "$0")/.."

SOURCE_URL="https://setup.rbxcdn.com/api_dump.json"
DEST="${1:-tools/api-dump.json}"

echo "Fetching Roblox API dump from $SOURCE_URL -> $DEST"
if curl -sL --fail --max-time 120 "$SOURCE_URL" -o "$DEST"; then
	echo "OK: downloaded $(stat -c %s "$DEST") bytes to $DEST"
	echo "Next: convert $DEST to tools/globalTypes.d.luau (JSON -> Luau type declarations)."
else
	echo "WARN: download failed (mirror may be blocked). Using hand-written tools/globalTypes.d.luau instead."
	echo "Update SOURCE_URL in this script when a reachable mirror is known."
fi
