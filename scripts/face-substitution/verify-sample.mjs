import {access, mkdir, readFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {assertComparableMedia, makeFrameTimes} from './media.mjs';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDirectory, '..', '..');
const config = JSON.parse(await readFile(path.join(root, 'config', 'face-substitution.json'), 'utf8'));
const output = path.join(root, 'output', 'source-style-face-substitution', 'facefusion', 'face-substitution-sample-15s.mp4');
const review = path.join(root, 'output', 'source-style-face-substitution', 'verification');
const ffmpeg = spawnSync('python', ['-c', 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())'], {encoding: 'utf8'}).stdout.trim();

const inspectMedia = (input) => {
  const result = spawnSync(ffmpeg, ['-hide_banner', '-i', input, '-f', 'null', 'NUL'], {encoding: 'utf8'});
  if (result.status !== 0) {
    throw new Error(result.stderr || `FFmpeg could not inspect ${input}`);
  }
  const dimensions = result.stderr.match(/Video:.*?(\d{3,5})x(\d{3,5})/s);
  const hasAudio = /Audio:\s+aac\b/i.test(result.stderr);
  if (!dimensions) {
    throw new Error(`Video stream metadata missing for ${input}`);
  }
  return {
    width: Number(dimensions[1]),
    height: Number(dimensions[2]),
    hasAudio,
  };
};

await access(output);
await mkdir(review, {recursive: true});
const sourceMedia = inspectMedia(config.sourceVideo);
const outputMedia = inspectMedia(output);
assertComparableMedia(sourceMedia, outputMedia);
if (outputMedia.width !== config.expectedWidth || outputMedia.height !== config.expectedHeight) {
  throw new Error(`Unexpected output dimensions: ${outputMedia.width}x${outputMedia.height}`);
}

for (const seconds of makeFrameTimes(config.sampleDurationSeconds, 5)) {
  const name = `final-${seconds.toFixed(1).replace('.', '_')}.jpg`;
  const result = spawnSync(ffmpeg, [
    '-y', '-hide_banner', '-loglevel', 'error', '-ss', String(seconds), '-i', output,
    '-frames:v', '1', '-q:v', '2', path.join(review, name),
  ], {encoding: 'utf8'});
  if (result.status !== 0) {
    throw new Error(result.stderr || `FFmpeg failed at ${seconds}s`);
  }
}

console.log(JSON.stringify({output, review, frameTimes: makeFrameTimes(config.sampleDurationSeconds, 5)}));
