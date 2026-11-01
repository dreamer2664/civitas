#!/usr/bin/env bash
# Installs the pinned verification toolchain (Linux x86_64) into ~/.local/bin, and the Roblox type
# definitions and API dump into ~/.cache/civitas. Idempotent.
# Versions are pinned so every agent's evidence is reproducible. Re-run is idempotent.
set -euo pipefail
BIN="${CIV_BIN:-$HOME/.local/bin}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$BIN"

SELENE_VERSION=0.32.0
LUAU_LSP_VERSION=1.70.1
LUNE_VERSION=0.11.1
ROJO_VERSION=7.7.1
STYLUA_VERSION=2.6.0

fetch() { # url dest-binary-name
  curl -fsSL "$1" -o "$TMP/pkg.zip"
  unzip -oq "$TMP/pkg.zip" -d "$TMP/x"
  find "$TMP/x" -type f \( -name "$2" \) -exec install -m 0755 {} "$BIN/$2" \;
  rm -rf "$TMP/x" "$TMP/pkg.zip"
  echo "installed $2"
}

fetch "https://github.com/Kampfkarren/selene/releases/download/${SELENE_VERSION}/selene-${SELENE_VERSION}-linux.zip" selene
fetch "https://github.com/JohnnyMorganz/luau-lsp/releases/download/${LUAU_LSP_VERSION}/luau-lsp-linux-x86_64.zip" luau-lsp
fetch "https://github.com/lune-org/lune/releases/download/v${LUNE_VERSION}/lune-${LUNE_VERSION}-linux-x86_64.zip" lune
fetch "https://github.com/rojo-rbx/rojo/releases/download/v${ROJO_VERSION}/rojo-${ROJO_VERSION}-linux-x86_64.zip" rojo
fetch "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/stylua-linux-x86_64.zip" stylua

"$BIN/selene" --version
"$BIN/luau-lsp" --version
"$BIN/lune" --version
"$BIN/rojo" --version
"$BIN/stylua" --version

# Roblox type definitions for luau-lsp, and the Roblox API dump used by tools/check_enums.py.
# Downloaded once into the user cache, not into the repository. The luau-lsp definitions are pinned
# to the release tag; the API dump tracks the Roblox-Client-Tracker branch, so `verify.sh` prints its
# SHA-256 each run and the evidence records which dump was used.
CACHE="${CIV_CACHE:-$HOME/.cache/civitas}"
mkdir -p "$CACHE"
if [ ! -s "$CACHE/globalTypes.d.lua" ]; then
  curl -fsSL "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/${LUAU_LSP_VERSION}/scripts/globalTypes.d.lua" -o "$CACHE/globalTypes.d.lua"
fi
if [ ! -s "$CACHE/Full-API-Dump.json" ]; then
  curl -fsSL "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Full-API-Dump.json" -o "$CACHE/Full-API-Dump.json"
fi
echo "definitions: $CACHE/globalTypes.d.lua"
echo "api dump:    $CACHE/Full-API-Dump.json (sha256 $(sha256sum "$CACHE/Full-API-Dump.json" | cut -d' ' -f1))"
