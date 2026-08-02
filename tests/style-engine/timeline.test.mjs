import test from 'node:test';
import assert from 'node:assert/strict';
import { validateTimeline } from '../../project/scripts/timeline.mjs';

const base = {
  version: 2,
  fps: 60,
  width: 1280,
  height: 720,
  targetDurationSeconds: 120,
  avatarReferenceVideo: 'mp4/shuziren1.mp4',
  referenceVideo: 'mp4/9e61c373398f12c4179ae3a2ba24060b_raw.mp4',
  derivedAssets: ['avatar/identity-primary.jpg', 'generated/narration.wav'],
  safeArea: { left: 56, right: 56, top: 42, bottom: 52 },
  captionBounds: { left: 104, right: 1176, top: 535, bottom: 666 },
  scenes: [
    {
      id: 'hook-01',
      start: 0,
      duration: 120,
      layout: 'presenter-wide',
      caption: { zh: 'AI真正的爆发期还没到来', en: 'The AI explosion has not fully arrived' },
      overlays: [{ type: 'source-strip', text: 'THE NEXT AI WAVE' }],
      broll: [{ type: 'generated-abstract', label: 'GPU GRID' }],
    },
  ],
};

test('rejects a timeline when duration is outside the two-minute contract', () => {
  assert.throws(() => validateTimeline({ ...base, targetDurationSeconds: 90 }), /115-125/);
});

test('rejects vertical timelines', () => {
  assert.throws(() => validateTimeline({ ...base, width: 1080, height: 1920, fps: 30 }), /1280x720.*60fps/);
});

test('rejects reference video or extracted reference frames as output assets', () => {
  assert.throws(() => validateTimeline({ ...base, scenes: [{ ...base.scenes[0], asset: 'analysis/frames/t-000.jpg' }] }), /reference asset/i);
  assert.throws(() => validateTimeline({ ...base, scenes: [{ ...base.scenes[0], asset: 'mp4/9e61c373398f12c4179ae3a2ba24060b_raw.mp4' }] }), /reference asset/i);
});

test('rejects direct use of the avatar reference video as scene footage', () => {
  assert.throws(() => validateTimeline({ ...base, scenes: [{ ...base.scenes[0], asset: 'mp4/shuziren1.mp4' }] }), /avatar reference/i);
  assert.throws(() => validateTimeline({ ...base, scenes: [{ ...base.scenes[0], visual: { type: 'presenter', asset: 'mp4/shuziren1.mp4' } }] }), /avatar reference/i);
});

test('rejects captions outside the horizontal safe area', () => {
  assert.throws(() => validateTimeline({ ...base, captionBounds: { left: 0, right: 1280, top: 0, bottom: 720 } }), /safe area/i);
});

test('accepts a valid source-style scene contract', () => {
  assert.doesNotThrow(() => validateTimeline(base));
});
