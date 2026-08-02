import test from 'node:test';
import assert from 'node:assert/strict';
import {
  assertComparableMedia,
  makeFrameTimes,
} from '../../scripts/face-substitution/media.mjs';

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
