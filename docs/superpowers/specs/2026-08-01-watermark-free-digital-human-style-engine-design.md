# Watermark-Free Digital Human Style Engine

## Goal

Create a local, repeatable production workflow that accepts a presenter video and a script, then renders a new approximately two-minute vertical video using the reference video's measurable style language:

- dark presenter base with deliberate color accents;
- frequent information-card interruptions;
- small uppercase section labels;
- large Chinese captions with optional English support text;
- animated metrics, comparison bars, lists, charts, and screenshot-like cards;
- a decisive hook, explanatory middle, and compact conclusion.

The reference MP4 is an analysis input only. Its frames, watermark, captions, attribution, audio, and identifiable creator content are excluded from generated outputs.

## Inputs

- Reference video: `mp4/9e61c373398f12c4179ae3a2ba24060b_raw.mp4`
- Presenter source: `mp4/shuziren1.mp4`
- Script/timeline JSON: `project/timeline/demo-2min.json`
- Optional future TTS WAV: `project/audio/narration.wav`
- Optional future generated B-roll assets: `project/assets/*`

The presenter source is a 37-second, 4K, 60fps portrait recording whose pixels are stored upside down. Preprocessing rotates it 180 degrees, creates a 1080x1920 clean master, and records the safe loop ranges. The first demo uses looped/cut presenter footage and a generated synthetic narration track. It does not claim phoneme-level lip-sync until a user-approved lip-sync engine is installed.

## Architecture

```text
reference MP4
  -> analysis scripts
  -> style-spec.json + rhythm map + component inventory

presenter MP4 + script JSON
  -> presenter preprocessing
  -> narration adapter
  -> Remotion composition
  -> FFmpeg encode
  -> media/visual policy checks
```

Remotion owns composition, scene timing, captions, cards, charts, and controlled camera motion. FFmpeg owns rotation, scaling, format normalization, audio synthesis/muxing, and final H.264/AAC output. The timeline JSON is the contract between copy, timing, assets, and render code.

## Demo narrative

The first output uses a new script distilled from the reference topic rather than copying its wording:

1. Hook: AI's real opportunity is not the loudest demo.
2. Problem: most people repeat tool usage without moving into a valuable position.
3. Explanation: value comes from combining domain judgment, workflow design, and reusable assets.
4. Method: build one small production loop, measure it, and compound the result.
5. Correction: more prompts alone do not create leverage.
6. Close: use AI to amplify a craft you already understand.

Target runtime is 120 seconds at 30fps, 1080x1920. The scene plan uses 6 blocks and a card or visual change every 4-9 seconds.

## Visual system

```json
{
  "canvas": "1080x1920",
  "fps": 30,
  "background": "#091016",
  "text": "#f4f7fa",
  "muted": "#aeb8c2",
  "blue": "#56a8ff",
  "red": "#ff5666",
  "green": "#62e8a1",
  "yellow": "#f2db65",
  "safeArea": { "left": 72, "right": 72, "top": 96, "bottom": 164 },
  "caption": { "position": "bottom", "maxLines": 2, "keywordColor": "#62e8a1" },
  "changeIntervalSeconds": { "min": 4, "max": 9 }
}
```

Cards are opaque enough to read over the presenter but retain the presenter silhouette when layered. Face and mouth regions remain clear. No card is allowed to obscure the central face box for more than a brief transition.

## Skills

The first two project-local skills are:

- `skills/analyzing-reference-video-style/SKILL.md`: extracts measurable style tokens and explicitly excludes source assets from the output.
- `skills/rendering-watermark-free-digital-human-video/SKILL.md`: assembles a new timeline from user-owned presenter footage and new assets, with no-watermark checks.

Each new Skill must have a baseline scenario recorded before its document is written, following the writing-skills TDD rule.

## Verification

Every generated demo must produce:

- MP4 with 1080x1920, 30fps, 115-125 seconds;
- no reference-video frames, source watermark, attribution, or source audio stream;
- no black frames or missing video/audio streams;
- caption bounds inside the safe area;
- a contact sheet at representative times;
- JSON media report and render log.

Visual review checks mobile-sized frames as well as full-resolution frames. Media verification is independent of the renderer and is run after every render.

## Out of scope for this pass

- installing a new plugin, Skill, TTS model, or lip-sync model;
- face substitution of the reference MP4;
- cloning the original creator's voice or identity;
- using the original watermark-bearing video as a hidden background layer;
- claiming exact pixel-for-pixel reproduction of a third-party video.
