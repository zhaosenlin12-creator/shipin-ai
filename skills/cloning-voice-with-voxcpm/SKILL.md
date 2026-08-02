---
name: cloning-voice-with-voxcpm
description: Use when a user-owned voice reference, Voicebox, Qwen3-TTS, VoxCPM, voice clone, TTS pack, narration WAV, reference transcript, or reusable Chinese narration adapter is needed for a digital-human video.
---

# Cloning Voice With Voicebox Or VoxCPM

Create one render-ready narration track from a user-approved voice reference. Prefer the configured Voicebox Qwen3-TTS adapter when it is available; never label fallback TTS as voice cloning.

## Contract

- Use approved reference media only to create a mono `16 kHz` WAV and aligned reference text.
- Generate by semantic paragraph, never by 4-second scene cadence. Keep Qwen chunks below `180` Chinese characters and join only at sentence boundaries.
- Produce a single narration WAV, a JSON provenance record, and a mastered `48 kHz` WAV.
- Keep reference media outside render manifests. Final audio must be newly synthesized, never copied from the reference video.

## Voicebox Qwen Workflow

1. Extract `project/reference/avatar/avatar-voice-reference-16k.wav` from the approved source.
2. Transcribe and correct its text before production cloning. The reference transcript must describe the spoken reference audio, not the requested narration.
3. Generate the full script with `scripts/voicebox-generate-clone.py`. It uses the local Qwen model cache and persists `voiceMode: voicebox-qwen-tts` plus `referenceTextMode: aligned-text`.
4. Master the result with `scripts/master-voicebox-narration.ps1` to apply measured light denoise, a target near `-15 LUFS`, a `-1.5 dBTP` ceiling, and `48 kHz` PCM. Use `-DisableDenoise` only after auditioning proves the generated voice is cleaner untreated.
5. Use the mastered WAV in the avatar and video render. Do not re-split it to match visual scene length.

```powershell
$py = 'tools\voicebox\.venv\Scripts\python.exe'
& $py scripts\voicebox-transcribe-reference.py `
  --audio project\reference\avatar\avatar-voice-reference-16k.wav `
  --output project\reference\avatar\avatar-voice-reference.txt `
  --cache-dir tools\voicebox\model-cache

& $py scripts\voicebox-generate-clone.py `
  --text-file project\script.txt `
  --reference-audio project\reference\avatar\avatar-voice-reference-16k.wav `
  --reference-text-file project\reference\avatar\avatar-voice-reference.txt `
  --output project\public\narration-voicebox.wav `
  --status-output project\output\verification\voicebox-status.json `
  --cache-dir tools\voicebox\model-cache

powershell -NoProfile -ExecutionPolicy Bypass -File scripts\master-voicebox-narration.ps1 `
  -InputAudio project\public\narration-voicebox.wav `
  -OutputAudio project\public\narration.wav
```

## Runtime Choice

| Runtime | Use | Label |
| --- | --- | --- |
| Voicebox Qwen with aligned reference text | Default reusable local clone | `voicebox-qwen-tts` |
| Voicebox without aligned text | Short diagnostic only | `x-vector-only` |
| VoxCPM | Use when its model/runtime is verified | `voxcpm` |
| Any generic TTS | Keep pipeline runnable only | `fallback-tts` |

Use CPU only for short diagnostics. Generate long narration on an RTX 4060-class GPU or stronger when available.

## Acceptance

- Status JSON names the actual engine and references the approved WAV hash.
- `referenceTextMode` is `aligned-text` for production output.
- Final WAV is a single `48 kHz` narration stream with spoken loudness near the target and no clipped peak.
- Final MP4 contains the synthesized narration, not an audio stream copied from the source reference.

## Failure Rules

- If `transformers` cannot find system FFmpeg, load the normalized WAV with `soundfile` and pass raw samples to the ASR pipeline.
- If PowerShell blocks the master script, invoke it with `-ExecutionPolicy Bypass`; FFmpeg success is determined by its exit code, not harmless stderr layout hints.
- Do not claim a clone is complete when the only output is Edge TTS, source audio, or an unmastered quiet WAV.
