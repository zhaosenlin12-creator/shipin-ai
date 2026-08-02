# shipin-ai
Reusable pipeline for producing horizontal Chinese explainers with:

- Voicebox Qwen voice cloning from an approved user-owned reference.
- Denoised, mastered, continuous narration from a full script.
- Ditto audio-driven presenter generation for head motion, eyes, expression, and lip sync.
- HyperFrames composition, captions, cards, B-roll, and final H.264/AAC delivery.

## Continue On Another Computer

1. Clone this repository.
2. Read [docs/SESSION-HANDOFF.md](docs/SESSION-HANDOFF.md) before changing the pipeline.
3. Keep private reference media outside Git and restore the local paths listed in the handoff.
4. On an RTX 4060 machine, prepare Ditto checkpoints and run the 15-second smoke test before a full render.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\prepare-ditto-smoke-bundle.ps1 `
  -OutputDirectory .\local\ditto-smoke-bundle
```

The smoke bundle is intentionally generated locally and is not committed because it contains identity and voice assets.

## Key Commands

```powershell
# Generate a cloned narration from a full script.
& tools\voicebox\.venv\Scripts\python.exe scripts\voicebox-generate-clone.py `
  --text-file project\script.txt `
  --reference-audio project\reference\avatar\avatar-voice-reference-16k.wav `
  --reference-text-file project\reference\avatar\avatar-voice-reference.txt `
  --output project\public\narration-voicebox.wav `
  --status-output project\output\verification\voicebox-status.json `
  --cache-dir tools\voicebox\model-cache

# Denoise and master the narration for video.
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\master-voicebox-narration.ps1 `
  -InputAudio project\public\narration-voicebox.wav `
  -OutputAudio project\public\narration.wav

# Render a fresh Ditto avatar from a generated presenter image and the mastered WAV.
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run-ditto-avatar.ps1 `
  -AudioPath project\public\narration.wav `
  -SourceImage project\public\generated\presenter-user-avatar-neutral.png `
  -OutputVideo project\public\generated\presenter-ditto.mp4
```

## Privacy Boundary

Do not commit raw avatar videos, source-platform videos, voice-reference WAVs, personal identity images, model caches, API keys, or generated private videos. The repository contains the production logic and handoff, not the user's biometric source material.
