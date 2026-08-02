import { assertSafeAssetPath, isAvatarReferencePath } from './media-policy.mjs';

const MIN_DURATION = 115;
const MAX_DURATION = 125;
const SAFE = { left: 56, right: 56, top: 42, bottom: 52 };

function assertText(value, message) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(message);
  }
}

function assertSafeOptionalAsset(assetPath) {
  if (!assetPath) return;
  assertSafeAssetPath(assetPath);
}

export function validateTimeline(timeline) {
  if (!Number.isInteger(timeline.fps) || timeline.fps !== 60 || timeline.width !== 1280 || timeline.height !== 720) {
    throw new Error('Timeline must be 1280x720 horizontal at 60fps');
  }
  if (timeline.targetDurationSeconds < MIN_DURATION || timeline.targetDurationSeconds > MAX_DURATION) {
    throw new Error('Timeline target duration must be 115-125 seconds');
  }
  assertText(timeline.referenceVideo, 'Timeline needs a reference video for analysis traceability');
  assertText(timeline.avatarReferenceVideo, 'Timeline needs an avatar reference video for identity and voice extraction');
  if (!isAvatarReferencePath(timeline.avatarReferenceVideo)) {
    throw new Error('avatarReferenceVideo must point to the approved avatar reference video');
  }
  for (const asset of timeline.derivedAssets ?? []) {
    assertSafeAssetPath(asset);
  }

  const safeArea = timeline.safeArea ?? SAFE;
  const bounds = timeline.captionBounds;
  if (bounds) {
    if (bounds.left < safeArea.left || bounds.right > timeline.width - safeArea.right
      || bounds.top < safeArea.top || bounds.bottom > timeline.height - safeArea.bottom) {
      throw new Error('Caption bounds exceed safe area');
    }
  }

  let cursor = 0;
  const scenes = timeline.scenes ?? [];
  if (scenes.length < 1) throw new Error('Timeline needs at least one scene');

  for (const scene of scenes) {
    assertText(scene.id, 'Each scene needs an id');
    if (scene.start !== cursor) {
      throw new Error(`Scene ${scene.id} must start at ${cursor}`);
    }
    if (scene.duration <= 0) throw new Error(`Scene ${scene.id} needs positive duration`);
    assertText(scene.layout, `Scene ${scene.id} needs a layout`);
    assertText(scene.caption?.zh, `Scene ${scene.id} needs Chinese caption text`);
    assertSafeOptionalAsset(scene.asset);
    assertSafeOptionalAsset(scene.visual?.asset);
    for (const item of scene.broll ?? []) assertSafeOptionalAsset(item.asset);
    for (const item of scene.overlays ?? []) assertText(item.type, `Scene ${scene.id} has overlay without type`);
    cursor += scene.duration;
  }

  if (Math.abs(cursor - timeline.targetDurationSeconds) > 0.001) {
    throw new Error('Scene durations must add up to targetDurationSeconds');
  }

  return true;
}
