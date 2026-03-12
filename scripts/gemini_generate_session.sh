#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE_DIR="$ROOT/state"
mkdir -p "$STATE_DIR"

CDP_PORT="${CDP_PORT:-9222}"
CHROME_BIN="${CHROME_BIN:-google-chrome}"
CHROME_PROFILE_DIR="${CHROME_PROFILE_DIR:-$HOME/.cache/chrome-gemini-debug}"
GEMINI_URL="${GEMINI_URL:-https://gemini.google.com/}"

cat <<EOF
Gemini web session bootstrap (CDP mode)

1) Start a dedicated Chrome profile with remote debugging:
   $CHROME_BIN --remote-debugging-port=$CDP_PORT --user-data-dir=$CHROME_PROFILE_DIR

2) In that Chrome window, open Gemini and complete login manually if needed:
   $GEMINI_URL

3) When Gemini is fully ready, press Enter here.
EOF

read -r _

mkdir -p "$STATE_DIR"
cat > "$STATE_DIR/session.env" <<EOF
CDP_PORT=$CDP_PORT
CHROME_BIN=$CHROME_BIN
CHROME_PROFILE_DIR=$CHROME_PROFILE_DIR
GEMINI_URL=$GEMINI_URL
EOF

echo "Saved session config: $STATE_DIR/session.env"
echo "CDP mode uses your real Chrome profile at: $CHROME_PROFILE_DIR"
