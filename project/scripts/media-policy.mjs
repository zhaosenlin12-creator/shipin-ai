import path from 'node:path';

const referenceName = '9e61c373398f12c4179ae3a2ba24060b_raw.mp4';
const avatarReferenceNames = new Set(['shuziren1.mp4', '数字人.mp4']);

export function isForbiddenSourcePath(assetPath) {
  if (!assetPath) return false;
  const normalized = assetPath.replaceAll('\\', '/').toLowerCase();
  return normalized.includes(referenceName.toLowerCase())
    || normalized.includes('analysis/frames')
    || normalized.includes('analysis/reference-first120')
    || normalized.includes('source-style-face-substitution')
    || normalized.includes('douyin')
    || normalized.includes('抖音');
}

export function isAvatarReferencePath(assetPath) {
  if (!assetPath) return false;
  const filename = path.basename(assetPath.replaceAll('\\', '/')).toLowerCase();
  return avatarReferenceNames.has(filename);
}

export function assertSafeAssetPath(assetPath) {
  if (isForbiddenSourcePath(assetPath)) {
    throw new Error(`Forbidden reference asset: ${assetPath}`);
  }
  if (isAvatarReferencePath(assetPath)) {
    throw new Error(`Forbidden avatar reference footage: ${assetPath}`);
  }
  return path.normalize(assetPath);
}

export function validateOutputMetadata(metadata) {
  if (metadata.width !== 1280 || metadata.height !== 720) {
    throw new Error('Output must be 1280x720');
  }
  if (Math.abs(metadata.fps - 60) > 0.1) {
    throw new Error('Output must be 60fps');
  }
  if (metadata.duration < 115 || metadata.duration > 125) {
    throw new Error('Output duration must be 115-125 seconds');
  }
  if (!metadata.hasVideo || !metadata.hasAudio) {
    throw new Error('Output must contain video and audio streams');
  }
  return true;
}
