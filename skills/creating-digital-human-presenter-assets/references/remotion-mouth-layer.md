# Remotion Mouth Layer Notes

The mouth overlay should be subtle. If the patch flickers or creates a visible rectangle, reduce opacity, tighten the clip rectangle, or blur the mask edge with a radial CSS mask.

Recommended checks:

- Render frame 120 for hook scenes.
- Render frame 300 for presenter-card scenes.
- Render one late presenter return frame after B-roll.
- Inspect that card overlays stay right of the mouth and captions stay below the chin.

If the generated assets have different pixel dimensions, CSS `objectFit: cover` keeps them aligned as long as framing is nearly identical. If framing drifts, regenerate the neutral image from the open-mouth image, not from the raw reference frame.
