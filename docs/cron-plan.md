# OpenClaw Cron Plan

## Recommended schedule

Example recurring runs:
- 08:00
- 11:00
- 14:00
- 17:00

## Delivery modes

- announce: send summary back to chat after each run
- none: silent background runs that only write artifacts

## Suggested job split

### Job A: build content package
- topic selection
- asset generation
- selection
- payload draft

### Job B: publish
- upload selected assets
- fill post form
- submit or save draft

Keeping them split reduces failure blast radius.
