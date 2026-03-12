#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SESSION_ENV="$ROOT/state/session.env"
if [ -f "$SESSION_ENV" ]; then
  # shellcheck disable=SC1090
  source "$SESSION_ENV"
fi

export PATH="$HOME/.npm-global/bin:$PATH"
CDP_PORT="${CDP_PORT:-9222}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$HOME/下载}"
if [ ! -d "$DOWNLOAD_DIR" ]; then
  DOWNLOAD_DIR="${DOWNLOAD_DIR_FALLBACK:-$HOME/Downloads}"
fi

TOPIC="${1:-测试主题}"
PROMPT="${2:-为\"$TOPIC\"生成一张适合小红书封面的高质量插画图片，构图清晰，主体突出，色彩干净，适合移动端浏览。}"
RUN_DATE="$(date +%F)"
RUN_TS="$(date +%F-%H%M%S)"
SAFE_TOPIC="$(printf '%s' "$TOPIC" | tr ' /' '__')"
OUT_DIR="$ROOT/artifacts/$RUN_DATE/$RUN_TS-$SAFE_TOPIC"
mkdir -p "$OUT_DIR/screenshots"

run_ab() {
  agent-browser --cdp "$CDP_PORT" "$@"
}

paste_image_to_gemini() {
  local image_path="$1"
  python3 "$ROOT/scripts/set_image_clipboard.py" "$image_path"
  run_ab find label "为 Gemini 输入提示" click || true
  run_ab key Control+V || true
}

json_escape() {
  python3 - <<'PY' "$1"
import json,sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
}

STARTED_AT="$(date --iso-8601=seconds)"
PROMPT_JSON=$(json_escape "$PROMPT")
TOPIC_JSON=$(json_escape "$TOPIC")
cat > "$OUT_DIR/run.json" <<JSON
{
  "topic": $TOPIC_JSON,
  "prompt": $PROMPT_JSON,
  "startedAt": "$STARTED_AT",
  "status": "started"
}
JSON
printf '%s\n' "$PROMPT" > "$OUT_DIR/prompt.txt"

before_list="$OUT_DIR/downloads.before.txt"
after_list="$OUT_DIR/downloads.after.txt"
ls -1t "$DOWNLOAD_DIR" 2>/dev/null > "$before_list" || true

run_ab open "https://gemini.google.com/app" || true
run_ab wait 3000 || true
# Force a clean new-chat state before each run (avoid tooltip text collisions)
run_ab eval '
(() => {
  const btn = document.querySelector("[data-test-id=new-chat-button] button, [data-test-id=new-chat-button]");
  if (!btn) return {ok:false, reason:"no-new-chat-button"};
  btn.click();
  return {ok:true};
})()' || true
run_ab wait 2000 || true
run_ab screenshot "$OUT_DIR/screenshots/01-open.png" || true
run_ab snapshot -i --json > "$OUT_DIR/01-open.snapshot.json" || true

# Optional reference attachment via browser clipboard paste (no upload dialog)
REFS_DIR="${REFS_DIR:-}"
if [ -n "$REFS_DIR" ] && [ -d "$REFS_DIR" ]; then
  mapfile -t REF_FILES < <(find "$REFS_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | head -n 3)
  if [ "${#REF_FILES[@]}" -gt 0 ]; then
    paste_ok=0
    for ref_file in "${REF_FILES[@]}"; do
      paste_image_to_gemini "$ref_file" || true
      run_ab wait 1200 || true
    done
    run_ab wait 1500 || true
    run_ab snapshot -i -c > "$OUT_DIR/01b-paste-check.txt" || true
    if grep -Eq '移除文件|图片预览' "$OUT_DIR/01b-paste-check.txt"; then
      paste_ok=1
    fi
    if [ "$paste_ok" -ne 1 ]; then
      run_ab screenshot "$OUT_DIR/screenshots/01b-paste-failed.png" || true
      cat > "$OUT_DIR/result.json" <<JSON
{
  "status": "upload_failed",
  "message": "Reference images were not confirmed on page after clipboard paste; generation aborted."
}
JSON
      echo "Reference paste not confirmed; aborting run: $OUT_DIR"
      exit 3
    fi
    printf '%s\n' "${REF_FILES[@]}" > "$OUT_DIR/uploaded-refs.txt"
    run_ab screenshot "$OUT_DIR/screenshots/01b-uploaded-refs.png" || true
  fi
fi

# Dynamic Gemini UI sequence with strict pre-send validation
run_ab find text "制作图片" click || true
run_ab fill 'textarea, div[contenteditable="true"], input[aria-label*="Gemini"], input[placeholder*="Gemini"]' "$PROMPT" 2>/dev/null || \
run_ab find label "为 Gemini 输入提示" fill "$PROMPT" || true
run_ab snapshot -i --json > "$OUT_DIR/02-filled.snapshot.json" || true
run_ab snapshot -i -c > "$OUT_DIR/02-filled.snapshot.txt" || true

# Require prompt area + refs attached (if REFS_DIR provided) before send
if [ -n "$REFS_DIR" ] && [ -d "$REFS_DIR" ]; then
  if ! grep -Eq '移除文件|图片预览' "$OUT_DIR/02-filled.snapshot.txt"; then
    cat > "$OUT_DIR/result.json" <<JSON
{
  "status": "refs_not_attached",
  "message": "Reference files were expected but not visible before send."
}
JSON
    echo "References not attached before send: $OUT_DIR"
    exit 4
  fi
fi
if ! grep -q '为 Gemini 输入提示' "$OUT_DIR/02-filled.snapshot.txt"; then
  cat > "$OUT_DIR/result.json" <<JSON
{
  "status": "prompt_box_missing",
  "message": "Prompt box not visible before send."
}
JSON
  echo "Prompt box missing before send: $OUT_DIR"
  exit 5
fi

send_started=0
# click first
run_ab find text "发送" click || true
run_ab wait 1800 || true
run_ab snapshot -i -c > "$OUT_DIR/02-postsend.snapshot.txt" || true
if grep -Eq '停止回答|正在加载 Nano Banana 2' "$OUT_DIR/02-postsend.snapshot.txt"; then
  send_started=1
else
  # Enter fallback
  run_ab find label "为 Gemini 输入提示" focus || true
  run_ab press Enter || true
  run_ab wait 1800 || true
  run_ab snapshot -i -c > "$OUT_DIR/02-postsend-enter.snapshot.txt" || true
  if grep -Eq '停止回答|正在加载 Nano Banana 2' "$OUT_DIR/02-postsend-enter.snapshot.txt"; then
    send_started=1
  fi
fi
if [ "$send_started" -ne 1 ]; then
  cat > "$OUT_DIR/result.json" <<JSON
{
  "status": "send_not_started",
  "message": "Neither click nor Enter transitioned page into generating state."
}
JSON
  echo "Send did not start generation: $OUT_DIR"
  exit 6
fi
run_ab wait 12000 || true
run_ab screenshot "$OUT_DIR/screenshots/02-generating.png" || true

# Wait until result actions show up. Retry a few times.
found_download=0
for i in 1 2 3 4 5; do
  run_ab snapshot -i -c > "$OUT_DIR/03-result-$i.snapshot.txt" || true
  if grep -q '下载完整尺寸的图片' "$OUT_DIR/03-result-$i.snapshot.txt"; then
    found_download=1
    break
  fi
  run_ab wait 5000 || true
done

if [ "$found_download" -ne 1 ]; then
  run_ab screenshot "$OUT_DIR/screenshots/03-timeout.png" || true
  cat > "$OUT_DIR/result.json" <<JSON
{
  "status": "generation_timeout",
  "message": "Did not detect download button within retry window."
}
JSON
  echo "Generation did not finish in time: $OUT_DIR"
  exit 2
fi

run_ab screenshot "$OUT_DIR/screenshots/03-result.png" || true
run_ab find text "下载完整尺寸的图片" click || true
sleep 5
ls -1t "$DOWNLOAD_DIR" 2>/dev/null > "$after_list" || true

NEW_FILE="$(python3 - <<'PY' "$before_list" "$after_list"
import sys
before=set()
after=[]
try:
    before=set(open(sys.argv[1], encoding='utf-8', errors='ignore').read().splitlines())
except FileNotFoundError:
    pass
try:
    after=open(sys.argv[2], encoding='utf-8', errors='ignore').read().splitlines()
except FileNotFoundError:
    after=[]
for name in after:
    if name and name not in before:
        print(name)
        break
PY
)"

DOWNLOADED_TO=""
if [ -n "$NEW_FILE" ] && [ -f "$DOWNLOAD_DIR/$NEW_FILE" ]; then
  mkdir -p "$OUT_DIR/downloads"
  cp "$DOWNLOAD_DIR/$NEW_FILE" "$OUT_DIR/downloads/$NEW_FILE"
  DOWNLOADED_TO="$OUT_DIR/downloads/$NEW_FILE"
fi

cat > "$OUT_DIR/result.json" <<JSON
{
  "status": "ok",
  "downloadDetected": $( [ -n "$DOWNLOADED_TO" ] && echo true || echo false ),
  "downloadedTo": $(json_escape "$DOWNLOADED_TO"),
  "finishedAt": "$(date --iso-8601=seconds)"
}
JSON

echo "Run finished: $OUT_DIR"
if [ -n "$DOWNLOADED_TO" ]; then
  echo "Downloaded file copied to: $DOWNLOADED_TO"
else
  echo "No new download file was confidently identified; inspect $DOWNLOAD_DIR and $OUT_DIR/screenshots"
fi
