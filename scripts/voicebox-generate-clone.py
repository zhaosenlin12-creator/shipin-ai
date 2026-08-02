#!/usr/bin/env python3
"""Generate one continuous, reusable Qwen voice-clone narration artifact."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
from pathlib import Path

import numpy as np
import soundfile as sf
import torch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--text-file", type=Path, required=True)
    parser.add_argument("--reference-audio", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--status-output", type=Path, required=True)
    parser.add_argument("--reference-text-file", type=Path)
    parser.add_argument("--model-id", default="Qwen/Qwen3-TTS-12Hz-0.6B-Base")
    parser.add_argument("--cache-dir", type=Path, required=True)
    parser.add_argument("--language", default="Chinese")
    parser.add_argument("--chunk-max-chars", type=int, default=180)
    parser.add_argument("--crossfade-ms", type=int, default=100)
    parser.add_argument("--threads", type=int, default=6)
    parser.add_argument("--seed", type=int, default=3407)
    parser.add_argument("--hf-endpoint", default="https://hf-mirror.com")
    return parser.parse_args()


def clean_text(text: str) -> str:
    return re.sub(r"[ \t]+", " ", text.replace("\r\n", "\n").replace("\r", "\n")).strip()


def split_text(text: str, max_chars: int) -> list[str]:
    """Split only on semantic Chinese boundaries, never timeline beat boundaries."""
    units = [item.strip() for item in re.split(r"(?<=[。！？；!?;])\s*|\n+", clean_text(text)) if item.strip()]
    chunks: list[str] = []
    buffer = ""
    for unit in units:
        if len(unit) <= max_chars and len(buffer) + len(unit) <= max_chars:
            buffer += unit
            continue
        if buffer:
            chunks.append(buffer)
            buffer = ""
        if len(unit) <= max_chars:
            buffer = unit
            continue
        parts = [part for part in re.split(r"(?<=[，、,:：])", unit) if part]
        long_buffer = ""
        for part in parts:
            if long_buffer and len(long_buffer) + len(part) > max_chars:
                chunks.append(long_buffer)
                long_buffer = part
            else:
                long_buffer += part
        if long_buffer:
            chunks.append(long_buffer)
    if buffer:
        chunks.append(buffer)
    if not chunks:
        raise ValueError("Narration text is empty after normalization")
    return chunks


def join_audio(parts: list[np.ndarray], crossfade_samples: int) -> np.ndarray:
    output = np.asarray([], dtype=np.float32)
    for part in parts:
        part = np.asarray(part, dtype=np.float32).reshape(-1)
        if output.size == 0:
            output = part
            continue
        overlap = min(crossfade_samples, output.size, part.size)
        if overlap:
            fade_out = np.linspace(1.0, 0.0, overlap, dtype=np.float32)
            fade_in = 1.0 - fade_out
            output = np.concatenate((output[:-overlap], output[-overlap:] * fade_out + part[:overlap] * fade_in, part[overlap:]))
        else:
            output = np.concatenate((output, part))
    peak = float(np.max(np.abs(output))) if output.size else 0.0
    return output if peak <= 0.98 else output * (0.98 / peak)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def local_snapshot(model_id: str, cache_dir: Path) -> Path | None:
    snapshot_root = cache_dir / ("models--" + model_id.replace("/", "--")) / "snapshots"
    if not snapshot_root.is_dir():
        return None
    candidates = sorted(snapshot_root.iterdir(), reverse=True)
    for candidate in candidates:
        required = (candidate / "config.json", candidate / "model.safetensors", candidate / "speech_tokenizer" / "config.json")
        if candidate.is_dir() and all(path.is_file() for path in required):
            return candidate
    return None


def main() -> None:
    args = parse_args()
    for path in (args.text_file, args.reference_audio):
        if not path.is_file():
            raise FileNotFoundError(path)
    if args.reference_text_file and not args.reference_text_file.is_file():
        raise FileNotFoundError(args.reference_text_file)

    os.environ["HF_HOME"] = str(args.cache_dir)
    os.environ["HF_ENDPOINT"] = args.hf_endpoint
    args.cache_dir.mkdir(parents=True, exist_ok=True)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.status_output.parent.mkdir(parents=True, exist_ok=True)
    torch.set_num_threads(max(1, args.threads))
    torch.manual_seed(args.seed)

    text = clean_text(args.text_file.read_text(encoding="utf-8"))
    chunks = split_text(text, args.chunk_max_chars)
    reference_text = clean_text(args.reference_text_file.read_text(encoding="utf-8")) if args.reference_text_file else None
    x_vector_only = reference_text is None

    snapshot = local_snapshot(args.model_id, args.cache_dir)
    if snapshot:
        os.environ["HF_HUB_OFFLINE"] = "1"
        os.environ["TRANSFORMERS_OFFLINE"] = "1"
    from qwen_tts import Qwen3TTSModel

    model = Qwen3TTSModel.from_pretrained(
        str(snapshot) if snapshot else args.model_id,
        cache_dir=str(args.cache_dir),
        torch_dtype=torch.float32,
        low_cpu_mem_usage=False,
        local_files_only=bool(snapshot),
    )
    voice_prompt = model.create_voice_clone_prompt(
        ref_audio=str(args.reference_audio),
        ref_text=reference_text,
        x_vector_only_mode=x_vector_only,
    )
    parts: list[np.ndarray] = []
    sample_rate: int | None = None
    for chunk in chunks:
        wavs, rate = model.generate_voice_clone(
            text=chunk,
            language=args.language,
            voice_clone_prompt=voice_prompt,
            non_streaming_mode=True,
        )
        if sample_rate is not None and sample_rate != rate:
            raise RuntimeError(f"Unexpected sample-rate change: {sample_rate} -> {rate}")
        sample_rate = rate
        parts.append(wavs[0])

    assert sample_rate is not None
    merged = join_audio(parts, int(sample_rate * args.crossfade_ms / 1000))
    sf.write(args.output, merged, sample_rate, subtype="PCM_16")
    status = {
        "voiceMode": "voicebox-qwen-tts",
        "modelId": args.model_id,
        "modelSource": str(snapshot.resolve()) if snapshot else args.model_id,
        "device": "cpu",
        "referenceAudio": str(args.reference_audio.resolve()),
        "referenceAudioSha256": sha256(args.reference_audio),
        "referenceTextMode": "aligned-text" if reference_text else "x-vector-only",
        "chunkCount": len(chunks),
        "chunks": chunks,
        "durationSeconds": round(len(merged) / sample_rate, 3),
        "sampleRate": sample_rate,
        "output": str(args.output.resolve()),
    }
    args.status_output.write_text(json.dumps(status, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(status, ensure_ascii=False))


if __name__ == "__main__":
    main()
