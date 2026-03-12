# xhs-browser-automation

A fresh OpenClaw-first browser automation scaffold for a Xiaohongshu content workflow.

This project does **not** reuse code from `meskills`.
It only borrows the high-level workflow logic:

1. choose a city/topic
2. generate or collect candidate assets
3. rank/select assets
4. build post payload
5. publish on a schedule
6. log artifacts for review

## Planned runtime

- Browser automation: Agent Browser / browser-driven tasks
- Scheduling: OpenClaw cron
- Outputs: JSON artifacts + markdown run summaries

## Current scope

This repo contains:
- workflow design
- task specs
- scheduler wrapper skeleton
- artifact directory structure

## Gemini web automation quick start

### 1. Start dedicated Chrome with CDP

```bash
google-chrome --remote-debugging-port=9222 --user-data-dir=$HOME/.cache/chrome-gemini-debug
```

### 2. Bootstrap session config

```bash
bash scripts/gemini_generate_session.sh
```

### 3. Run one Gemini image generation

```bash
bash scripts/gemini_generate_run.sh "杭州西湖剪纸风"
```

### 4. Run with local reference images

```bash
REFS_DIR=/absolute/path/to/refs bash scripts/gemini_generate_run.sh "义乌｜阳光下成长｜剪纸作品" "请参考已上传图片，生成一张适合小学生艺术节参赛的红色剪纸作品图，主题为义乌、阳光下成长、儿童校园氛围，主体明确，纯白背景，竖版3:4。"
```

### 5. Batch-generate body images

```bash
REFS_DIR=/absolute/path/to/refs bash scripts/gemini_batch_generate.sh "义乌｜阳光下成长｜剪纸作品" "义乌" "阳光下成长"
```

### 6. Generate a cover from selected/generated images

```bash
REFS_DIR=/absolute/path/to/body-images bash scripts/gemini_generate_cover.sh "义乌｜阳光下成长｜剪纸作品" "义乌" "阳光下成长"
```

### 7. Experimental: paste a local image into Gemini without upload dialog

```bash
bash scripts/gemini_paste_image_experiment.sh /absolute/path/to/image.png
```

This uses the browser clipboard API plus `Ctrl+V`, and verifies the page shows `图片预览` / `移除文件`.

Artifacts are written under:

```bash
artifacts/YYYY-MM-DD/<timestamp>-<topic>/
```

## Next steps

- make Gemini UI selectors more resilient than fixed refs
- improve download-file detection
- add post-processing / selection steps
- implement publish flow
- connect cron delivery/reporting
