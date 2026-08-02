import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { validateTimeline } from '../../project/scripts/timeline.mjs';

test('source-style first120 timeline is a complete horizontal two-minute contract', async () => {
  const timeline = JSON.parse(await readFile(
    new URL('../../project/timeline/source-style-first120.json', import.meta.url),
    'utf8',
  ));
  assert.doesNotThrow(() => validateTimeline(timeline));
  assert.equal(timeline.width, 1280);
  assert.equal(timeline.height, 720);
  assert.equal(timeline.targetDurationSeconds, 120);
  assert.ok(timeline.scenes.length >= 20);
});

test('presenter and B-roll plates are visible on the first frame of each scene', async () => {
  const source = await readFile(
    new URL('../../project/src/SourceStyleVideo.tsx', import.meta.url),
    'utf8',
  );
  assert.doesNotMatch(source, /opacity:\s*enter\(localFrame,\s*20\)/);
  assert.doesNotMatch(source, /opacity:\s*enter\(localFrame,\s*16\)/);
});
