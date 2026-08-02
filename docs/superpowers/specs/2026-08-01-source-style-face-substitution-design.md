# Source-Style Face Substitution Design

**Goal:** Produce and validate a 15-second 1280x720, 60 fps sample that preserves the source video's composition, motion, captions, audio, B-roll, and pacing while replacing only the primary presenter's face with the user's consented identity.

**Scope:** This is the fidelity-validation stage. It creates a face-substituted version of an existing source video; it does not yet create an independent digital presenter or a reusable editing template for new scripts.

## Inputs

- Source master: `C:\kaifa_senlin\shipin-ai\mp4\9e61c373398f12c4179ae3a2ba24060b_raw.mp4`
  - 1280x720 landscape, approximately 59.84 fps, 8:56.54 duration.
- Identity reference: `C:\JSYSOFT\weixin1\xwechat_files\wxid_irc74agob6ju22_f059\msg\video\2026-08\2d7586ef8d3e30a5654ab0fe981bca6b_raw.mp4`
  - 3840x2160 HEVC with portrait rotation metadata, 60 fps, 4.76 seconds.
  - The user designated this recording as their identity reference.

## Output

- A derivative `output\source-style-face-substitution\sample-15s.mp4`.
- It covers a 15-second single-presenter interval chosen after face-tracking inspection of the source master.
- It retains the source's original audio and all non-presenter pixels.
- The presenter's face is the only intended modified region. Other speakers, B-roll subjects, screenshots, captions, watermarks, and graphics are unchanged.

## Architecture

1. Extract several sharp, frontal frames from the identity reference and select one primary identity image after visual review.
2. Inspect source face tracks and choose a 15-second interval containing exactly one continuous primary-presenter face track.
3. Use FaceFusion in reference-face mode to replace only that track. The selected identity image is the replacement source; all unmatched faces are explicitly preserved.
4. Encode the composited frames with the original timing, dimensions, and audio stream.
5. Compare source and output at fixed timestamps. Verify the new face is stable and the source layout, subtitles, audio timing, and non-face elements are preserved.

## Fidelity Rules

- Do not generate, crop, recolor, or re-time any source material outside the primary-presenter face mask.
- Do not replace faces in B-roll, embedded interviews, profile images, or product screenshots.
- Preserve the source's 1280x720 landscape frame, approximately 60 fps cadence, and original AAC audio.
- Keep source captions, creator attribution, and watermarks intact during this validation stage because they are part of the reference output being measured.
- Abort the selected interval if identity matching selects more than one face track or if the presenter is occluded for a material portion of the interval.

## Tooling And Constraints

- Face substitution engine: `facefusion/facefusion` (OpenRAIL-AS license). Its license must be reviewed before any commercial release.
- The current GTX 1060 with 6 GB VRAM is sufficient only for a short, lower-throughput face-substitution sample; it is not the long-form avatar engine.
- No face data is uploaded to a third-party service in this stage.
- Source files are read-only inputs. All intermediate frames, FaceFusion models, and encoded outputs live under `C:\kaifa_senlin\shipin-ai`.

## Acceptance Criteria

1. The sample opens and plays for 15 seconds without missing audio, black frames, or cadence changes.
2. The output reports 1280x720 video, approximately 60 fps, and an AAC audio stream.
3. At five fixed timestamps, the primary presenter visibly matches the user's identity reference while the face is temporally stable across adjacent frames.
4. At the same timestamps, captions, graphics, room lighting, framing, and non-presenter subjects match the source video.
5. The output contains no unintended face replacement in B-roll or secondary speakers.
6. The generated result is reviewed side-by-side with the source before any full-duration render is attempted.

## Non-Goals

- Reconstructing clean original assets hidden behind burned-in captions or watermarks.
- Claiming the face-substituted source as a fully generated avatar.
- Producing the final reusable skill in this validation pass.

