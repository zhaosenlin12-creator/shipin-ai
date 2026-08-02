import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';

const readSkill = (name) =>
  readFile(new URL(`../../skills/${name}/SKILL.md`, import.meta.url), 'utf8');

test('reference style skill captures horizontal source-style distillation requirements', async () => {
  const skill = await readSkill('analyzing-reference-video-style');
  assert.match(skill, /1280x720/);
  assert.match(skill, /60fps/);
  assert.match(skill, /120 seconds|120-second|two-minute/i);
  assert.match(skill, /shot inventory/i);
  assert.match(skill, /sourceOnly/);
  assert.doesNotMatch(skill, /1080x1920/);
});

test('rendering skill targets clean horizontal digital-human output', async () => {
  const skill = await readSkill('rendering-watermark-free-digital-human-video');
  assert.match(skill, /horizontal/i);
  assert.match(skill, /1280x720/);
  assert.match(skill, /60fps/);
  assert.match(skill, /VoxCPM/);
  assert.match(skill, /lip|mouth|phoneme/i);
  assert.match(skill, /avatar reference/i);
  assert.match(skill, /do not|never|reject/i);
  assert.doesNotMatch(skill, /vertical explainer/i);
  assert.doesNotMatch(skill, /1080x1920/);
  assert.doesNotMatch(skill, /30fps/);
});
