#!/usr/bin/env bash
set -euo pipefail

SESSION="${AGENT_BROWSER_SESSION:-gemini-xhs}"
URL="${GEMINI_URL:-https://gemini.google.com/}"
STATE_DIR="$(cd "$(dirname "$0")/.." && pwd)/state"
mkdir -p "$STATE_DIR"

echo "[1/3] Opening Gemini in headed mode for manual auth bootstrap..."
agent-browser --session "$SESSION" open "$URL" --headed

echo "[2/3] Complete login manually in the opened browser if needed."
echo "    After Gemini is ready, press Enter here to save session state."
read -r _

echo "[3/3] Saving browser state..."
agent-browser --session "$SESSION" state save "$STATE_DIR/gemini-auth.json"

echo "Saved: $STATE_DIR/gemini-auth.json"
