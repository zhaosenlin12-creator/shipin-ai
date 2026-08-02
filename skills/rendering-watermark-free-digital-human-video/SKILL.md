---
name: rendering-watermark-free-digital-human-video
description: Use when a script and user-approved avatar or voice references must become a clean horizontal digital-human explainer with animated cards, captions, B-roll, and no third-party source footage or watermarks.
---

# Rendering Watermark-Free Digital Human Video

## Core rule

The reference video can calibrate timing and visual grammar, but it is never a render asset. Reject reference MP4 paths, extracted reference frames, original audio, platform marks, creator attribution, and watermark crops from the output manifest.

The avatar reference video is also not scene footage. Treat it as identity, mouth/lip motion, pose, and voice-pack evidence only. A renderer may use a generated avatar image, a trained digital-human model, a VoxCPM voice derivative, or a phoneme/lip-sync output created from those references, but it must not splice the raw avatar reference video into the final cut.

## Pipeline

1. Validate the source-style timeline: 120 seconds, horizontal `1280x720`, `60fps`, scene bounds, caption safe area, and asset ownership.
2. Prepare clean presenter assets from approved sources: generated still, digital-human model output, or avatar/lip-sync render. Do not use the raw avatar reference as scene footage.
3. Prepare narration through the configured voice adapter. Prefer VoxCPM for a reusable voice pack when dependencies and GPU/remote runtime are available.
4. If VoxCPM or lip sync is unavailable, keep the pipeline runnable with a clearly labeled synthetic TTS track and do not claim mouth or voice cloning is complete.
5. Render each scene from clean presenter assets, generated B-roll, and renderer-native cards, grids, captions, chapter labels, and progress indicators.
6. Encode H.264/AAC or H.264/PCM-derived audio with stable horizontal `1280x720` and `60fps`.
7. Run media validation, contact-sheet generation, and the no-reference-asset audit.

## Timeline contract

Each scene must contain:

```json
{
  "id": "s001-hook",
  "start": 0,
  "duration": 4,
  "layout": "presenter-card",
  "tone": "blue",
  "caption": { "zh": "New approved Chinese line", "en": "New English support line" },
  "chapter": { "eyebrow": "QUESTION 01", "title": "WHEN DOES IT START?", "accent": "blue" },
  "visual": { "type": "presenter", "asset": "generated/presenter-darkroom.png", "motion": "push-in" },
  "card": { "type": "stat", "label": "ACTIVE USERS", "value": "0.04%", "accent": "blue" }
}
```

Scene changes should land on the measured cadence, typically 4 seconds for the current horizontal source style. Keep the face and mouth readable, and never place a metric card over the mouth or lower-third captions.

## Voice and lip-sync adapter

| Stage | Requirement |
| --- | --- |
| Voice pack | Use VoxCPM or another approved TTS adapter only after the reference audio is user-owned or explicitly approved |
| Phonemes | Save word/phoneme timings or a mouth-open curve next to the narration artifact |
| Avatar render | Drive a generated avatar or model output from phonemes; do not cut-loop the user video and call it lip sync |
| Fallback | Label Edge TTS or other synthetic narration as fallback, and keep it replaceable by the VoxCPM output path |

## Render safety checks

- Reject any input or asset path containing the reference MP4 filename, `analysis/frames`, a watermark crop, or original creator attribution.
- Reject any scene asset path containing the avatar reference filename unless it is listed as a training/reference input outside the render manifest.
- Reject timeline captions that exactly match known source captions when reuse has not been approved for the requested proof window.
- Verify the output has no reference audio stream by comparing stream hashes or source fingerprints.
- Verify output duration, `1280x720` dimensions, `60fps`, and both audio/video streams after encode, not before.

## Common mistakes

| Mistake | Correction |
| --- | --- |
| Dropping the user's raw avatar video into the render | Generate or model a clean avatar output first |
| Calling presenter footage an avatar model | Describe it as a presenter source until a model generates new lip motion |
| Adding music from the reference | Use a new generated/royalty-cleared bed or silence |
| Rendering before timeline validation | Validate JSON and asset policy first |
| Saying VoxCPM voice cloning is done when using fallback TTS | State fallback status and keep the voice adapter path swappable |

## Acceptance checks

- A fresh MP4 plays from first to last frame with both streams present.
- Duration is 115-125 seconds, dimensions are `1280x720`, and frame rate is `60fps`.
- No source watermark, source frame, source caption, creator handle, or source audio is present.
- No raw avatar reference footage is present in the rendered timeline.
- Captions and cards stay inside safe bounds and do not create accidental overlaps.
