---
name: analyzing-reference-video-style
description: Use when a reference video must be distilled into reusable pacing, typography, captions, motion, cards, B-roll, and audio constraints without copying frames, watermark, voice, creator identity, or source footage.
---

# Analyzing Reference Video Style

## Overview

Treat the reference as a measurement instrument. Extract observable rules and component recipes into structured data, then keep the reference media out of every generated composition.

For the current source-style pipeline, the target contract is horizontal `1280x720`, `60fps`, and a 120-second first-pass sample. Preserve those numbers unless a later reference analysis proves the source has a different contract.

## Required workflow

1. Record technical metadata: duration, frame rate, dimensions, audio streams, and orientation.
2. Sample the entire runtime at regular intervals and around scene changes. Do not infer the whole video from its opening.
3. For a two-minute proof, cover exactly the first 120 seconds unless the user asks for a different window.
4. Build a shot inventory with `start`, `end`, `duration`, `shotType`, `presenterRatio`, `cardType`, `captionPattern`, `transition`, and `confidence`.
5. Build style tokens separately from content observations. Tokens describe color, scale, safe areas, timing intervals, chapter cadence, caption sizes, card geometry, and component behavior.
6. Mark source-only elements: watermark, creator handle, original frames, extracted screenshots, original audio, platform UI, identifiable people, and any captions or wording that cannot be safely reused.
7. Convert repeated patterns into renderer components: `Hook`, `PresenterPlate`, `BrollPlate`, `MetricCard`, `ListCard`, `BarsCard`, `FlowCard`, `GridPanel`, `ChapterHeader`, and `Caption`.
8. Pressure-test the output policy before rendering: generated scenes must reference only new generated assets, approved user-owned avatar or voice derivatives, and newly recorded or synthesized audio.

## Output contract

```json
{
  "source": { "durationSeconds": 0, "width": 1280, "height": 720, "fps": 60 },
  "target": { "durationSeconds": 120, "width": 1280, "height": 720, "fps": 60 },
  "styleTokens": { "changeIntervalSeconds": { "min": 4, "max": 4 } },
  "shotInventory": [],
  "componentInventory": [],
  "sourceOnly": [],
  "confidence": { "overall": 0, "notes": [] }
}
```

`sourceOnly` is mandatory. An analysis that omits the exclusion list is incomplete even when its visual observations are accurate.

## Current component grammar

| Component | Rule |
| --- | --- |
| Presenter plate | Full-frame clean generated or avatar-driven subject, slow push or drift, no source frame reuse |
| B-roll plate | New generated images only, slow pan or push, chapter header remains readable |
| Caption | Bottom centered Chinese primary line with English support line; keep within horizontal safe bounds |
| Cards | Right-side stat/list/bar/flow cards, 4-second scene cadence, animate in during the first 12-20 frames |
| Grid panel | Full-frame abstract population/resource visualization, no footage behind it |

## Common mistakes

| Mistake | Correction |
| --- | --- |
| Reusing a watermarked frame as a background | Rebuild the layout with a clean presenter source and new cards |
| Describing a video as fast | Record measured change intervals and representative cuts |
| Copying the entire original script into a generic demo | Reconstruct only the approved proof window or write new copy around the same abstract topic |
| Treating a contact sheet as full analysis | Sample the complete runtime and inspect transition neighborhoods |
| Calling a cut-loop lip-sync | Label it as timing-only until phoneme alignment is verified |

## Acceptance checks

- The full requested window is covered by the shot inventory.
- The first-pass proof is 120 seconds, horizontal `1280x720`, and `60fps`.
- Every repeated visual pattern has a renderer component or an explicit reason to omit it.
- The exclusion list is present and is checked by the renderer.
- No generated asset path points into the reference-video directory.
