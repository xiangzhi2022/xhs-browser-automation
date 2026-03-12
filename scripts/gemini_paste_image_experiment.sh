#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.npm-global/bin:$PATH"

IMAGE_PATH="${1:-}"
if [ -z "$IMAGE_PATH" ] || [ ! -f "$IMAGE_PATH" ]; then
  echo "Usage: $0 /absolute/or/relative/image.png" >&2
  exit 2
fi

IMAGE_PATH="$(python3 - <<'PY' "$IMAGE_PATH"
import os,sys
print(os.path.abspath(sys.argv[1]))
PY
)"

TMP_B64="$(mktemp)"
python3 - <<'PY' "$IMAGE_PATH" > "$TMP_B64"
import base64,sys
with open(sys.argv[1],'rb') as f:
    print(base64.b64encode(f.read()).decode())
PY
B64="$(cat "$TMP_B64")"
rm -f "$TMP_B64"

agent-browser --cdp 9222 eval "(async () => { const b64 = '$B64'; const bytes = Uint8Array.from(atob(b64), c => c.charCodeAt(0)); const blob = new Blob([bytes], {type: 'image/png'}); await navigator.clipboard.write([new ClipboardItem({'image/png': blob})]); return {ok:true}; })()"
agent-browser --cdp 9222 find label '为 Gemini 输入提示' click
agent-browser --cdp 9222 key Control+V
agent-browser --cdp 9222 wait 2000 || true
agent-browser --cdp 9222 snapshot -i -c > /tmp/gemini-paste-check.txt

if grep -Eq '图片预览|移除文件' /tmp/gemini-paste-check.txt; then
  echo "PASTE_OK"
else
  echo "PASTE_FAILED" >&2
  sed -n '1,160p' /tmp/gemini-paste-check.txt >&2 || true
  exit 1
fi
