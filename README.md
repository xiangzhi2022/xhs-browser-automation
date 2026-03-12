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
