import test from 'node:test';
import assert from 'node:assert/strict';
import { isForbiddenSourcePath, validateOutputMetadata } from '../../project/scripts/media-policy.mjs';

test('identifies reference media and extracted reference frames', () => {
  assert.equal(isForbiddenSourcePath('mp4/9e61c373398f12c4179ae3a2ba24060b_raw.mp4'), true);
  assert.equal(isForbiddenSourcePath('analysis/frames/t-000.jpg'), true);
  assert.equal(isForbiddenSourcePath('project/assets/generated-chart.png'), false);
});

test('requires horizontal 1280x720 60fps output with both streams', () => {
  assert.throws(() => validateOutputMetadata({ width: 1080, height: 1920, fps: 30, duration: 120, hasVideo: true, hasAudio: true }), /1280x720/);
  assert.throws(() => validateOutputMetadata({ width: 1280, height: 720, fps: 30, duration: 120, hasVideo: true, hasAudio: true }), /60fps/);
  assert.throws(() => validateOutputMetadata({ width: 1280, height: 720, fps: 60, duration: 120, hasVideo: true, hasAudio: false }), /audio/i);
  assert.doesNotThrow(() => validateOutputMetadata({ width: 1280, height: 720, fps: 60, duration: 120, hasVideo: true, hasAudio: true }));
});
