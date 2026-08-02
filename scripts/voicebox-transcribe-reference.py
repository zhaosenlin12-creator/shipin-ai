#!/usr/bin/env python3
"""Create aligned Chinese reference text for a Voicebox Qwen profile."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

import numpy as np
import soundfile as sf


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--audio", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--model", default="openai/whisper-base")
    parser.add_argument("--cache-dir", type=Path, required=True)
    parser.add_argument("--hf-endpoint", default="https://hf-mirror.com")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if not args.audio.is_file():
        raise FileNotFoundError(args.audio)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.cache_dir.mkdir(parents=True, exist_ok=True)
    os.environ["HF_HOME"] = str(args.cache_dir)
    os.environ["HF_ENDPOINT"] = args.hf_endpoint

    from transformers import pipeline

    recognizer = pipeline(
        "automatic-speech-recognition",
        model=args.model,
        device=-1,
    )
    # The reference is already normalized to WAV. Loading it directly avoids the
    # Transformers filename path, which shells out to a globally installed ffmpeg.
    audio, sample_rate = sf.read(args.audio, dtype="float32", always_2d=False)
    if audio.ndim == 2:
        audio = np.mean(audio, axis=1, dtype=np.float32)
    result = recognizer(
        {"raw": np.asarray(audio, dtype=np.float32), "sampling_rate": sample_rate},
        generate_kwargs={"language": "chinese", "task": "transcribe"},
    )
    text = result["text"].strip()
    if not text:
        raise RuntimeError("Whisper produced an empty transcript")
    args.output.write_text(text + "\n", encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
