# Gemini Web Automation Plan

## Goal

Use a real Gemini web account (no Google API key) to generate images through browser automation.

## Constraints

- Use Gemini web UI, not Gemini API
- Reuse an already-logged-in browser session when possible
- Keep the workflow deterministic and retryable
- Save all artifacts for later review

## Proposed flow

### Phase 0 — Browser session bootstrap
- Open Gemini in a headed browser once
- Complete human login manually if needed
- Save browser state with `agent-browser state save`
- Reuse that state for future scheduled runs

### Phase 1 — Open Gemini image generation page
- Load saved state
- Open Gemini web page
- Wait for the main composer to be ready
- Snapshot interactive elements

### Phase 2 — Submit prompt
- Fill the prompt box with a generated image prompt
- Optionally attach topic keywords
- Trigger image generation

### Phase 3 — Wait and collect results
- Wait for result cards / generated image thumbnails
- Take screenshots for debugging
- Extract image URLs if possible
- Download images into the run artifact directory
- Current verified Gemini UI markers from live testing:
  - prompt textbox appears as `textbox "为 Gemini 输入提示"`
  - image mode can appear as `button "🖼️ 制作图片"`
  - send button can appear as `button "发送"`
  - result actions can include `button "下载完整尺寸的图片"`

### Phase 4 — Build metadata
- Save prompt used
- Save topic / city / keywords
- Save generation timestamps
- Save downloaded asset list

### Phase 5 — Hand off to later pipeline steps
- Selection
- Cover composition
- Publish payload assembly

## Session strategy

Recommended:
- Use real Chrome via CDP instead of logging in inside a Playwright-managed browser
- Start Chrome with `--remote-debugging-port=9222 --user-data-dir=$HOME/.cache/chrome-gemini-debug`
- Let `agent-browser --cdp 9222 ...` control the already logged-in page
- Use headed mode during setup/debugging
- Use headless mode only after the flow is stable

## Verified live Gemini UI flow

Verified on this host with a real Gemini web account:
- open Gemini with `agent-browser --cdp 9222 open https://gemini.google.com/`
- textbox appears as `textbox "为 Gemini 输入提示"`
- image mode can appear as `button "🖼️ 制作图片"`
- send button can appear as `button "发送"`
- result actions can include `button "下载完整尺寸的图片"`
- upload menu path is:
  - `button "打开文件上传菜单"`
  - then `menuitem "上传文件. 文档、数据、代码文件"`

Verified upload workaround:
- click `打开文件上传菜单`
- click `上传文件. 文档、数据、代码文件`
- a hidden `input[type=file][name="Filedata"]` appears in the DOM
- use JS to temporarily make it visible/interactable
- then call `agent-browser upload 'input[type=file]' <files...>`

This successfully feeds local reference images into Gemini's upload flow on this host.

## Failure handling

- If login is lost: stop and request manual re-auth
- If prompt box is missing: re-snapshot and retry once
- If generation stalls: wait longer, then capture screenshot + page errors
- If downloads fail: save the result page screenshot and metadata anyway

## Deliverables per run

Under `artifacts/YYYY-MM-DD/<timestamp>-<topic>/`:
- `run.json`
- `prompt.txt`
- `generation.json`
- `downloads.json`
- `screenshots/*.png`
- `selected/` (later phase)
- `payload.json` (later phase)
