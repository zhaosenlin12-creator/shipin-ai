# Conversation Context Export

Updated: 2026-08-02

## Purpose

This is the portable conversation record for continuing the project on another computer. It preserves the user's requirements, corrections, supplied references, and accepted technical decisions in chronological order. It is deliberately a working-context export rather than a platform-native chat transcript. Private source media, personal voice samples, credentials, and source-platform watermarks are not included in Git.

Read this file together with `docs/SESSION-HANDOFF.md` before making any new implementation decisions.

## Original Request

The user asked to distill a supplied Douyin reference video into one or more reusable local Skills, targeting a one-to-one reproduction of its presentation style. The eventual production input should be a script plus the user's digital-human identity and voice, and the output should automatically become a video in the same high-quality style.

The user initially supplied the reference link for the style analysis and pointed to `zhaosenlin12-creator/cangjie-skill.git` as a repository that could be pulled for distillation work. The requested outcome was not a simple edit of the original video; it was reusable automation that can later process new content.

## Source Material Clarifications

1. The user supplied videos under `C:\kaifa_senlin\shipin-ai\mp4`.
2. A video described as a digital-human clip is an identity, voice, and motion reference. It is not scene footage that may be inserted as the final presenter layer.
3. The user supplied a separate original long video as the style/content reference, including a later 9-minute reference. The requirement is to analyze its pacing, presenter behavior, speech, graphics, animation components, and scene structure.
4. The target preview is the first two minutes, rendered horizontally, with the user's identity and voice replacing the original creator's identity and voice. The source-platform watermark must not be in the final output.
5. The later supplied `shuziren1.mp4` is the approved digital-human identity/voice reference for the private local workflow.

## User Corrections That Must Remain Binding

The user rejected an early output because it used the supplied avatar/reference footage as the final video and did not represent a generated digital presenter. This must never happen again.

The user then rejected a static-image / mouth-only approach because the person was motionless, the mouth did not appear convincingly animated, and the result looked mechanical. A professional digital human must have audio-driven lip movement plus believable head, eye, facial-expression, and idle motion.

The user also rejected fragmented narration and very quiet audio. Speech must be generated as continuous, naturally paced narration from the full script. It must be loud enough for ordinary playback after mastering, without harsh clipping or distracting background noise.

The request is explicitly for high-fidelity functional recreation of the reference's content rhythm and production grammar, while replacing the source person's identity and voice with the user's approved assets. It is not acceptable to call a downgraded static compositing workflow a one-to-one professional reconstruction.

## Voice Requirements And Decisions

The user supplied `OpenBMB/VoxCPM.git` as an early voice reference, then asked to pull and use `zhaosenlin12-creator/voicebox.git` to create a reusable dedicated TTS voice package from the approved avatar video's audio.

The user accepted the resulting cloned voice timbre as usable, but reported background noise. The reusable voice pipeline must therefore include noise reduction and mastering. The repository's committed Voicebox scripts use full-script narration rather than sentence-by-sentence clips and include denoise, loudness normalization, and output validation.

The private voice reference and generated voice outputs are intentionally excluded from public Git because they are personal biometric media. The code and instructions to reproduce them are included.

## Digital Presenter Requirements And Decisions

The user asked whether a GitHub/open-source project could create a natural digital human and emphasized that the presenter quality must approach the natural state seen in the supplied second Douyin example. The accepted production direction is an audio-driven talking-head model, not merely Wav2Lip over a static image.

Ditto (`antgroup/ditto-talkinghead`) was selected as the serious open-source evaluation route because it is intended to drive portrait movement from audio. The current repository vendors the Ditto source and contains a runner, but does not include model checkpoints, private identity images, or private narration audio.

The user asked whether an RTX 4060 can run this route. It must be verified by an actual 15-second smoke render on that machine before promising production capacity. The initial test must evaluate VRAM, speed, lip alignment, head/eye motion, face stability, and output quality.

## Production Target

Given a new Chinese script and the user's approved private identity/voice references, the intended pipeline should produce a roughly two-minute horizontal explainer with:

- Continuous cloned-voice narration.
- A natural audio-driven digital presenter.
- Reference-style pacing and scene transitions.
- Captions, information cards, B-roll, motion graphics, and other appropriate visual components.
- No Douyin watermark, creator handle, or reused raw source footage.

The original video should be treated as reference material for analysis and transformation, not as output footage to re-export.

## Current Boundary Between Public And Private Files

Committed to Git:

- Reusable Skills.
- Voice cloning, mastering, and presenter runner scripts.
- HyperFrames / Remotion composition source and tests.
- Ditto application source.
- This conversation context export and the technical handoff.

Deliberately excluded from Git:

- Personal raw avatar MP4 files and extracted voice clips.
- Generated identity images and user-specific voice WAV files.
- Model checkpoints, model caches, Python environments, and Node dependencies.
- Rendered output video files.
- Credentials, tokens, and environment files.

## Immediate Continuation Order

1. On the RTX 4060 computer, clone this repository.
2. Restore private avatar/voice assets by a secure local transfer; do not commit them.
3. Follow `docs/SESSION-HANDOFF.md` to prepare Ditto dependencies and checkpoints.
4. Run and inspect the 15-second Ditto smoke test.
5. Only after the presenter passes visual inspection, generate the full two-minute presenter layer and integrate it into the HyperFrames composition.
6. Keep iterating against the reference video's timing, speech continuity, motion, and graphics; do not silently fall back to a static or mouth-only avatar.

