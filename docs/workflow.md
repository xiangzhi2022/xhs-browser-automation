# Workflow Design

## Source logic extracted from meskills

The original repo represents an end-to-end Xiaohongshu posting pipeline:

1. pick a city/topic
2. generate visual candidates
3. score/select best images
4. build a cover
5. produce publish payload
6. publish on a fixed schedule

## Rebuilt automation plan (no code reuse)

### Phase 1 — Topic selection
- Maintain a rotating queue of cities/topics
- Avoid repeats within the same day
- Allow manual override for special campaigns

### Phase 2 — Asset generation/collection
- Browser automation opens the target image-generation or source website
- Submits prompt/topic data
- Waits for results
- Downloads/saves candidate assets into a timestamped run folder

### Phase 3 — Asset review/selection
- Keep a metadata file per candidate
- Rank candidates using a deterministic score rubric
- Select top N assets

### Phase 4 — Post packaging
- Build a cover asset from chosen topic/asset set
- Build a payload JSON containing:
  - title
  - body/caption
  - tags
  - selected images
  - publish metadata

### Phase 5 — Scheduled publish
- Open Xiaohongshu publish flow in the browser
- Upload cover + selected images
- Fill title/body/tags
- Submit or save draft
- Capture final confirmation screenshot / result JSON

### Phase 6 — Logging and recovery
- Save each run under `artifacts/YYYY-MM-DD/<timestamp>-<topic>/`
- Keep:
  - run.json
  - selected.json
  - payload.json
  - screenshots/
  - publish-result.json
- Support retry on temporary browser failures
