# Session Handoff

Updated: 2026-08-02

This document is the project continuation record for moving the work to another computer. It records the confirmed requirements, decisions, rejected approaches, current artifacts, verification evidence, and next execution steps. It intentionally excludes system-only instructions, credentials, raw private media, and platform watermarks.

## User Objective

Build a reusable local or hybrid production pipeline that accepts:

1. A new Chinese script.
2. The user's approved voice reference.
3. The user's approved identity/avatar reference.

It must produce a horizontal explainer around two minutes long with continuous narration, a natural digital presenter, captions, information cards, B-roll, motion graphics, and no source-platform watermark. The final video must use the user's identity and cloned voice, not the raw reference video as scene footage.

The visual target is the supplied short-video style: fast but controlled information beats, a presenter that remains readable, purposeful graphic overlays, clean captions, and natural speech. The user explicitly rejected static posing, only-mouth movement, fragmented narration, low volume, and the use of the raw avatar MP4 as the final presenter layer.

## Conversation Decisions In Order

1. The user asked for a one-to-one distillation of a Douyin reference style into reusable local Skills, using HyperFrames, Remotion, Superpowers, and the supplied `cangjie-skill` repository where useful.
2. The user supplied local video paths under `mp4/` and clarified that the avatar video is an identity, voice, and motion reference only. It must never be pasted into the final render.
3. The first static-image and Wav2Lip-based result was rejected because the person did not move naturally, only the mouth moved, and the voice was too quiet and segmented.
4. The user selected the `shuziren1.mp4` footage as the approved voice/avatar reference and asked for the first two minutes of a reusable production system rather than a watermarked copy of the source video.
5. The user supplied `OpenBMB/VoxCPM` and later `zhaosenlin12-creator/voicebox` as voice-related references. The working local implementation uses the cloned Voicebox repository with Qwen3-TTS because it produced a verified user-voice clone on this machine.
6. The user asked how to achieve the natural presenter state seen in another short-video example. The accepted diagnosis is that a professional result needs audio-driven facial/head motion, not a static pose plate with a mouth overlay.
7. The open-source presenter route was changed to Ditto (`antgroup/ditto-talkinghead`) for the first serious benchmark. LivePortrait remains useful for motion-template and portrait-motion experiments; it is not the complete audio-driven presenter by itself.
8. The user accepted the current voice timbre but reported background noise. A reusable denoise step was added to the mastering script and verified on the proof sample.
9. The user now wants the implementation and this project handoff uploaded to `zhaosenlin12-creator/shipin-ai.git` so another computer can pull it and continue without losing context.

## Current Production Architecture

```text
full Chinese script
  -> semantic script paragraphs
  -> Voicebox Qwen voice clone with aligned reference text
  -> highpass / lowpass / adaptive denoise / two-pass loudness master
  -> Ditto audio-driven presenter from generated identity image
  -> HyperFrames horizontal explainer composition
  -> captions, cards, B-roll, scene motion, H.264/AAC validation
```

Important separation of responsibilities:

- Voicebox owns voice identity and narration generation.
- The mastering script owns noise reduction, loudness, true peak, and 48 kHz delivery.
- Ditto owns audio-driven head, eye, expression, and lip motion.
- HyperFrames owns the explainer timeline and graphic composition.
- Raw user videos remain reference inputs outside the render manifest.

## Verified Voicebox State

Repository: `tools/voicebox/` locally only; its virtual environment and model cache are ignored by Git.

Runtime:

- Python 3.12 environment under `tools/voicebox/.venv`.
- CPU PyTorch works on the current GTX 1060 machine.
- Local Qwen model snapshot was downloaded under the ignored model cache.
- Reference audio was normalized to mono 16 kHz locally.

Reference artifacts, intentionally not committed:

- `project/reference/avatar/avatar-voice-reference-16k.wav`
- `project/reference/avatar/avatar-voice-reference.txt`

Reusable scripts committed in this repository:

- `scripts/voicebox-transcribe-reference.py`
- `scripts/voicebox-generate-clone.py`
- `scripts/master-voicebox-narration.ps1`
- `skills/cloning-voice-with-voxcpm/SKILL.md`

Verified proof artifacts, intentionally kept local because they contain user voice data:

- Raw cloned proof: `project/hyperframes-first120/assets/narration-voicebox-aligned-proof.wav`
- Clean mastered proof: `project/hyperframes-first120/assets/narration-voicebox-aligned-proof-clean-mastered.wav`
- Provenance: `project/hyperframes-first120/diagnostics/voicebox-aligned-proof-status.json`

Measured results on the proof sample:

- Voice engine: `voicebox-qwen-tts`.
- Reference mode: `aligned-text`.
- Duration: about 14.5 seconds.
- Output: mono 48 kHz PCM after mastering.
- Integrated loudness: about `-16.1 LUFS`.
- True peak: about `-1.5 dBTP`.
- Measured noise floor improved from about `-22.67 dB` to `-29.22 dB` after equal-loudness comparison of the mastered proof.

The old script failure modes were fixed:

- ASR no longer depends on a globally installed `ffmpeg`; it reads the normalized WAV directly with `soundfile`.
- PowerShell no longer treats harmless FFmpeg stderr layout hints as a failed process.
- Master output is fixed at 48 kHz instead of an unintended 192 kHz expansion.
- Denoise is on by default and can be disabled with `-DisableDenoise`.

## Verified Digital Presenter State

Ditto source was cloned into `tools/ditto-talkinghead/` locally. The repository source has no checkpoints; checkpoints must be downloaded separately on the target GPU machine and must remain ignored by Git.

Committed presenter files:

- `scripts/run-ditto-avatar.ps1`
- `scripts/prepare-ditto-smoke-bundle.ps1`
- `skills/creating-digital-human-presenter-assets/SKILL.md`

The Ditto runner:

- Accepts a mastered WAV and generated PNG/JPG presenter source.
- Resamples a temporary model input to mono 16 kHz.
- Requires CUDA and stops if CUDA is not available.
- Rejects raw avatar MP4 inputs.
- Supports overriding Ditto root, Python, FFmpeg, FFprobe, model root, and config paths for a small transferred bundle.
- Validates that the output video exists and contains media streams.

Preflight tests already passed:

- PowerShell syntax check passed for both Ditto scripts.
- Raw reference MP4 rejection passed.
- Missing Ditto runtime stops without static/Wav2Lip fallback.
- Digital-presenter Skill passed the local Skill validator.

## Hardware Reality

The current development machine is a GTX 1060 6 GB. It is suitable for short CPU Voicebox diagnostics and existing ONNX-based experiments, but it is not the target host for a natural Ditto presenter render.

The user's other machine is an RTX 4060. Do not promise full production success before measuring it. The correct next test is a 15-second Ditto smoke render, then inspect VRAM, output duration, face stability, eye movement, head movement, expression, and lip alignment. The official Ditto repository documents A100 testing and provides an Ampere_Plus TensorRT path; an RTX 4060 remains an unverified target until the smoke test passes.

## Minimal Transfer Plan

Do not move the whole current 13+ GB workspace. Do not move `tools/voicebox/.venv`, `tools/facefusion`, `project/node_modules`, raw MP4s, or model caches.

The generated local smoke bundle is about 3.92 MB and contains only:

- Ditto source code.
- The generated presenter image.
- A short denoised mastered narration proof.
- The Ditto runner and a manifest.

It is intentionally ignored by Git because it contains personal identity and voice assets. Generate it locally with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/prepare-ditto-smoke-bundle.ps1 `
  -OutputDirectory ./local/ditto-smoke-bundle
```

Transfer that local bundle securely to the RTX 4060, download Ditto checkpoints there, and run the smoke render. Keep the private avatar image and voice reference out of the public GitHub repository.

## Next Steps On The RTX 4060

1. Clone this repository.
2. Restore the private generated presenter image and mastered narration, or use the local smoke bundle.
3. Install Python 3.10, CUDA-compatible PyTorch, and Ditto's documented dependencies on the 4060 machine.
4. Download Ditto checkpoints into the local ignored `checkpoints/` directory.
5. Run the 15-second smoke render with `scripts/run-ditto-avatar.ps1`.
6. Measure peak VRAM and inspect a contact sheet at early, middle, and late frames.
7. If Ditto passes, generate the full two-minute presenter layer from the full Voicebox narration.
8. Only then rebuild the HyperFrames final composition.

## Non-Negotiable Quality Rules

- Never use the raw approved avatar MP4 as final scene footage.
- Never call a static image or Wav2Lip-only render a professional digital human.
- Never call generic fallback TTS a cloned voice.
- Never force narration into 4-second audio fragments.
- Never upload source-platform watermarks, creator handles, source audio, or private biometric media.
- If the Ditto preflight fails, stop and report it rather than silently degrading the presenter.
