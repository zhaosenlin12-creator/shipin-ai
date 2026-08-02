# Skill RED Baseline

The no-Skill baseline was run on 2026-08-01 with an independent agent. It correctly proposed full-runtime sampling, structured shot inventories, clean presenter preprocessing, and media validation. It also exposed these failure modes that the Skills must close:

- a 37-second presenter clip can be extended, but cut-loop footage must not be presented as phoneme-level lip sync;
- TTS and lip sync must remain adapters until a user-approved engine exists;
- the reference watermark, captions, audio, and source frames must be excluded explicitly;
- a “1:1” claim must be scoped to measurable style language, not third-party pixels, words, voice, or identity;
- final validation must check dimensions, duration, streams, black frames, safe captions, and reference-asset leakage.
