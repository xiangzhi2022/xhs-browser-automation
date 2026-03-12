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

### Phase 1 — Topic selection + reference planning
- Maintain a rotating queue of cities/topics
- Avoid repeats within the same day
- Allow manual override for special campaigns
- Produce `topic.json` with city/festival/keywords
- Produce `refs.json` with source URLs/snippets for later image collection

### Phase 2 — Reference asset collection
- Browser automation opens source/result websites
- Saves representative reference images into the run folder
- Records source URL and local file mapping
- Current status on this host:
  - source URLs/snippets are collected successfully
  - some local reference files are already being saved under `refs/`
  - quality filtering still needs improvement to avoid irrelevant PDFs/search pages

### Phase 3 — Asset generation/collection
- Browser automation opens the target image-generation website (Gemini web)
- Submits prompt/topic data
- Optionally uploads reference images from Phase 2
- Waits for results
- Downloads/saves generated assets into a timestamped run folder

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
