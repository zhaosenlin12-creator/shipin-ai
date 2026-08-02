# Source-Style Face Substitution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render and validate a 15-second source-style face-substitution sample using the user's identity reference while preserving the source video's timing, audio, graphics, and non-presenter faces.

**Architecture:** Extract a stable identity image and a single-presenter source interval, process that interval with a local FaceFusion checkout in reference-face mode, and assess the MP4 structurally and visually against the original interval. Small scripts make source paths, interval selection, and checks repeatable before this is expanded into a reusable style workflow.

**Tech Stack:** PowerShell, Node.js built-in test runner, FFmpeg from `imageio-ffmpeg`, FaceFusion 3.3.2, ONNX Runtime CUDA 1.22.0, and project-local CUDA 12/cuDNN 9 runtime libraries.

---

## File Structure

- Create: `config/face-substitution.json` - immutable input paths and selected sample interval.
- Create: `scripts/face-substitution/media.mjs` - FFmpeg process helpers and media metadata assertions.
- Create: `scripts/face-substitution/extract-identity.ps1` - creates identity reference frame candidates without altering the source video.
- Create: `scripts/face-substitution/extract-source-sample.ps1` - creates the selected source clip with stream-preserving audio.
- Create: `scripts/face-substitution/run-facefusion-sample.ps1` - runs a configured FaceFusion checkout against the sample clip.
- Create: `scripts/face-substitution/verify-sample.mjs` - verifies MP4 streams, duration, and deterministic comparison-frame output.
- Create: `tests/face-substitution/media.test.mjs` - tests source configuration and media assertion behavior before scripts consume real media.
- Create: `output/source-style-face-substitution/` - generated artifacts only; source inputs never live here.

### Task 1: Create The Input Contract And Media Test Helper

**Files:**
- Create: `tests/face-substitution/media.test.mjs`
- Create: `scripts/face-substitution/media.mjs`
- Create: `config/face-substitution.json`

- [ ] **Step 1: Write the failing test**

```js
import test from 'node:test';
import assert from 'node:assert/strict';
import {assertComparableMedia, makeFrameTimes} from '../../scripts/face-substitution/media.mjs';

test('creates five evenly spaced frame times inside a fifteen-second sample', () => {
  assert.deepEqual(makeFrameTimes(15, 5), [1.5, 4.5, 7.5, 10.5, 13.5]);
});

test('rejects output metadata that changes source dimensions or loses audio', () => {
  assert.throws(
    () => assertComparableMedia(
      {width: 1280, height: 720, hasAudio: true},
      {width: 720, height: 1280, hasAudio: false},
    ),
    /dimensions and AAC audio/,
  );
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/face-substitution/media.test.mjs`

Expected: FAIL because `scripts/face-substitution/media.mjs` does not exist.

- [ ] **Step 3: Write the minimal implementation and input config**

```js
// scripts/face-substitution/media.mjs
export const makeFrameTimes = (durationSeconds, count) =>
  Array.from({length: count}, (_, index) => Number((((index + 0.5) * durationSeconds) / count).toFixed(3)));

export const assertComparableMedia = (source, output) => {
  if (source.width !== output.width || source.height !== output.height || !output.hasAudio) {
    throw new Error('Output must preserve source dimensions and AAC audio');
  }
};
```

```json
{
  "sourceVideo": "C:\\kaifa_senlin\\shipin-ai\\mp4\\9e61c373398f12c4179ae3a2ba24060b_raw.mp4",
  "identityVideo": "C:\\JSYSOFT\\weixin1\\xwechat_files\\wxid_irc74agob6ju22_f059\\msg\\video\\2026-08\\2d7586ef8d3e30a5654ab0fe981bca6b_raw.mp4",
  "sampleStartSeconds": 15,
  "sampleDurationSeconds": 15,
  "expectedWidth": 1280,
  "expectedHeight": 720,
  "expectedFps": 60
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `node --test tests/face-substitution/media.test.mjs`

Expected: PASS with two tests.

- [ ] **Step 5: Commit**

Do not commit: `C:\kaifa_senlin\shipin-ai` is not a Git repository. Record the validation output in the task log instead.

### Task 2: Extract Identity Candidates And The Sample Source Clip

**Files:**
- Create: `scripts/face-substitution/extract-identity.ps1`
- Create: `scripts/face-substitution/extract-source-sample.ps1`
- Create: `output/source-style-face-substitution/identity/`
- Create: `output/source-style-face-substitution/source/`

- [ ] **Step 1: Verify the extraction precondition is absent**

Run:

```powershell
Test-Path output/source-style-face-substitution/identity/identity-primary.jpg
Test-Path output/source-style-face-substitution/source/source-sample-15s.mp4
```

Expected: both commands return `False`; the project has no generated identity or source-sample artifact yet.

- [ ] **Step 2: Implement the extraction scripts**

```powershell
# scripts/face-substitution/extract-identity.ps1
$ErrorActionPreference = 'Stop'
$ff = (python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())").Trim()
$input = 'C:\JSYSOFT\weixin1\xwechat_files\wxid_irc74agob6ju22_f059\msg\video\2026-08\2d7586ef8d3e30a5654ab0fe981bca6b_raw.mp4'
$output = 'C:\kaifa_senlin\shipin-ai\output\source-style-face-substitution\identity'
New-Item -ItemType Directory -Force -Path $output | Out-Null
& $ff -hide_banner -loglevel error -ss 2 -i $input -frames:v 1 -q:v 2 "$output\identity-primary.jpg"
```

```powershell
# scripts/face-substitution/extract-source-sample.ps1
$ErrorActionPreference = 'Stop'
$ff = (python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())").Trim()
$input = 'C:\kaifa_senlin\shipin-ai\mp4\9e61c373398f12c4179ae3a2ba24060b_raw.mp4'
$output = 'C:\kaifa_senlin\shipin-ai\output\source-style-face-substitution\source'
New-Item -ItemType Directory -Force -Path $output | Out-Null
& $ff -hide_banner -loglevel error -ss 15 -i $input -t 15 -map 0:v:0 -map 0:a:0 -c:v libx264 -preset medium -crf 16 -c:a copy "$output\source-sample-15s.mp4"
```

- [ ] **Step 3: Run scripts and verify generated artifacts**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/face-substitution/extract-identity.ps1
powershell -ExecutionPolicy Bypass -File scripts/face-substitution/extract-source-sample.ps1
node --test tests/face-substitution/media.test.mjs
```

Expected: output identity image and 15-second source MP4 exist; the Task 1 unit tests remain green.

- [ ] **Step 4: Commit**

Do not commit: workspace has no Git metadata.

### Task 3: Bootstrap And Validate FaceFusion Locally

**Files:**
- Create: `tools/facefusion/` - FaceFusion 3.3.2 checkout with a project-local Python environment.

- [ ] **Step 1: Write the failing availability check**

```powershell
# scripts/face-substitution/check-facefusion.ps1
$facefusion = 'C:\kaifa_senlin\shipin-ai\tools\facefusion\facefusion.py'
if (-not (Test-Path $facefusion)) {
  throw "FaceFusion entrypoint is missing: $facefusion"
}
```

- [ ] **Step 2: Run check to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File scripts/face-substitution/check-facefusion.ps1`

Expected: FAIL with `FaceFusion entrypoint is missing`.

- [ ] **Step 3: Bootstrap the pinned checkout and CUDA runtime**

```powershell
New-Item -ItemType Directory -Force -Path tools | Out-Null
git clone --depth 1 --branch 3.8.0 https://github.com/facefusion/facefusion.git tools/facefusion
Set-Location tools/facefusion
python install.py --onnxruntime cuda-12.8
python facefusion.py force-download --execution-providers cuda
```

- [ ] **Step 4: Verify the tool and CUDA provider**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File ..\..\scripts\face-substitution\check-facefusion.ps1
python facefusion.py headless-run --help
```

Expected: the entrypoint exists and its help lists `--source`, `--target`, `--output`, and a CUDA execution-provider option.

- [ ] **Step 5: Commit**

Do not commit: workspace has no Git metadata.

### Task 4: Render The Face-Substituted Sample

**Files:**
- Create: `scripts/face-substitution/run-facefusion-sample.ps1`
- Create: `output/source-style-face-substitution/facefusion/face-substitution-sample-15s.mp4`

- [ ] **Step 1: Verify the render precondition is absent**

Run: `Test-Path output/source-style-face-substitution/sample-15s.mp4`

Expected: `False`; no face-substituted sample exists before FaceFusion runs.

- [ ] **Step 2: Run FaceFusion in reference-face mode**

```powershell
# scripts/face-substitution/run-facefusion-sample.ps1
$ErrorActionPreference = 'Stop'
$root = 'C:\kaifa_senlin\shipin-ai'
$facefusion = Join-Path $root 'tools\facefusion'
$source = Join-Path $root 'output\source-style-face-substitution\identity\identity-primary.jpg'
$target = Join-Path $root 'output\source-style-face-substitution\source\source-sample-15s.mp4'
$output = Join-Path $root 'output\source-style-face-substitution\sample-15s.mp4'
Push-Location $facefusion
python facefusion.py headless-run --source $source --target $target --output $output --face-selector-mode reference --reference-face-position 0 --processors face_swapper face_enhancer --execution-providers cuda --output-video-resolution 1280x720 --output-video-fps 60
Pop-Location
```

- [ ] **Step 3: Run render and verify output exists**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/face-substitution/run-facefusion-sample.ps1
node --test tests/face-substitution/media.test.mjs
```

Expected: a playable MP4 exists at `output/source-style-face-substitution/sample-15s.mp4`.

- [ ] **Step 4: Commit**

Do not commit: workspace has no Git metadata.

### Task 5: Verify Media Structure And Visual Fidelity

**Files:**
- Create: `scripts/face-substitution/verify-sample.mjs`
- Create: `output/source-style-face-substitution/verification/`

- [ ] **Step 1: Write the failing verification test**

```js
test('uses exactly five deterministic review timestamps', () => {
  assert.deepEqual(makeFrameTimes(15, 5), [1.5, 4.5, 7.5, 10.5, 13.5]);
});
```

- [ ] **Step 2: Run test to verify it passes from Task 1**

Run: `node --test tests/face-substitution/media.test.mjs`

Expected: PASS; this guards review reproducibility while the verification script is added.

- [ ] **Step 3: Implement stream and frame verification**

```js
// scripts/face-substitution/verify-sample.mjs
import {mkdir, access} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {makeFrameTimes} from './media.mjs';

const ffmpeg = spawnSync('python', ['-c', 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())'], {encoding: 'utf8'}).stdout.trim();
const root = 'C:/kaifa_senlin/shipin-ai/output/source-style-face-substitution';
const output = `${root}/sample-15s.mp4`;
const review = `${root}/verification`;
await access(output);
await mkdir(review, {recursive: true});
for (const seconds of makeFrameTimes(15, 5)) {
  const name = `sample-${seconds.toFixed(1).replace('.', '_')}.jpg`;
  const result = spawnSync(ffmpeg, ['-hide_banner', '-loglevel', 'error', '-ss', String(seconds), '-i', output, '-frames:v', '1', '-q:v', '2', `${review}/${name}`], {encoding: 'utf8'});
  if (result.status !== 0) throw new Error(result.stderr || `FFmpeg failed at ${seconds}s`);
}
```

- [ ] **Step 4: Run verification and inspect the artifacts**

Run:

```powershell
node scripts/face-substitution/verify-sample.mjs
& (python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())") -hide_banner -i output/source-style-face-substitution/sample-15s.mp4 -f null NUL
```

Expected: five JPEG review frames exist and FFmpeg reports 1280x720 video, approximately 60 fps, and one AAC audio stream.

- [ ] **Step 5: Perform side-by-side acceptance review**

Compare the five rendered review frames against the same timestamps from `source-sample-15s.mp4`. Approve only when the presenter's face is stable, the identity reads as the user's reference, and non-presenter pixels, captions, graphics, and audio remain unchanged.

- [ ] **Step 6: Commit**

Do not commit: workspace has no Git metadata.
