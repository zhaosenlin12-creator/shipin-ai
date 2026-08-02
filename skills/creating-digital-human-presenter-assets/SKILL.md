---
name: creating-digital-human-presenter-assets
description: Use when an approved user avatar must become a natural, audio-driven digital presenter with head motion, eye movement, expression, and lip sync for a reusable video pipeline.
---

# Creating Audio-Driven Digital Presenters

Create a fresh presenter video from a generated identity-preserving image and newly synthesized narration. The approved avatar video is reference material for identity, voice, and motion only; it is never final scene footage.

## Production Rule

Do not use static pose switches, raw avatar footage, or Wav2Lip-only output as a professional digital human. Wav2Lip can be a diagnostic lip-sync proof only. Production output requires an audio-driven head-motion model such as Ditto, or an approved hosted avatar provider.

## Local Ditto Route

1. Create a clean presenter image in `project/public/generated/` from the approved identity reference. Keep the face large, frontal, and unobstructed.
2. Generate one denoised, mastered Voicebox narration WAV. Do not split it by visual scene cadence.
3. Render with `scripts/run-ditto-avatar.ps1`; it creates a temporary 16 kHz input for the model and rejects raw reference MP4 files.
4. Inspect an early, middle, and late contact sheet. Require changing eye state, head pose, and expression in addition to lip movement before using the clip in HyperFrames.
5. Use the new Ditto MP4 as the presenter layer. Add scene-level cards and B-roll separately in HyperFrames; never splice source footage.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run-ditto-avatar.ps1 `
  -AudioPath project\public\narration.wav `
  -SourceImage project\public\generated\presenter-user-avatar-neutral.png `
  -OutputVideo project\public\generated\presenter-ditto.mp4
```

## Runtime Choice

| Situation | Route |
| --- | --- |
| Local RTX 4060-class GPU with Ditto checkpoints | Ditto PyTorch model first; use the TensorRT variant only after a preflight succeeds. |
| Local model lacks natural long-form motion | Use a hosted avatar service with the approved voice/audio. |
| Only Wav2Lip is available | Produce a labeled lip-sync diagnostic, not a final digital-human clip. |

## Acceptance

- Input source is a generated `.png` / `.jpg`, not raw approved footage.
- Output contains video plus the newly synthesized narration stream.
- Contact-sheet inspection proves eyes, head, expression, and mouth all vary over time.
- Final timeline references only generated presenter output, not approved raw avatar MP4 files, source-video frames, source audio, or platform material.

## Failure Rules

- If CUDA, checkpoints, or a compatible Ditto runtime is missing, stop before render and report the preflight failure. Do not silently replace the output with a static image or Wav2Lip clip.
- If the generated source image has a poor face crop, regenerate the image before attempting model inference.
