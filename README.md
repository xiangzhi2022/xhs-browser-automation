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

## Next steps

- wire actual browser steps for target websites
- define login/session strategy
- implement publish flow
- connect cron delivery/reporting
