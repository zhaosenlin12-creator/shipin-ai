#!/usr/bin/env python3
import argparse
import importlib.util
import json
import shutil
import subprocess
import sys
from pathlib import Path


def run(args):
    completed = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return {
        "args": args,
        "returncode": completed.returncode,
        "stdout": completed.stdout.strip(),
        "stderr": completed.stderr.strip(),
    }


def package_status(names):
    return {name: importlib.util.find_spec(name) is not None for name in names}


def main():
    parser = argparse.ArgumentParser(description="Check VoxCPM voice adapter readiness and prepare reference audio.")
    parser.add_argument("--reference-video", required=True)
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--status-out", required=True)
    parser.add_argument("--ffmpeg", default=r"C:\kaifa_senlin\shipin-ai\tools\facefusion\bin\ffmpeg.exe")
    args = parser.parse_args()

    reference_video = Path(args.reference_video).resolve()
    out_dir = Path(args.out_dir).resolve()
    status_out = Path(args.status_out).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    status_out.parent.mkdir(parents=True, exist_ok=True)

    ffmpeg = Path(args.ffmpeg)
    if not ffmpeg.exists():
        found = shutil.which("ffmpeg")
        ffmpeg = Path(found) if found else ffmpeg

    reference_wav = out_dir / "avatar-voice-reference-16k.wav"
    extract = None
    if reference_video.exists() and ffmpeg.exists():
        extract = run([
            str(ffmpeg),
            "-hide_banner",
            "-y",
            "-i",
            str(reference_video),
            "-vn",
            "-ac",
            "1",
            "-ar",
            "16000",
            "-t",
            "30",
            "-af",
            "loudnorm=I=-18:TP=-1.5:LRA=11",
            str(reference_wav),
        ])

    nvidia = run(["nvidia-smi"]) if shutil.which("nvidia-smi") else None
    packages = package_status(["voxcpm", "torch", "torchaudio", "transformers", "soundfile", "librosa"])
    ready = reference_wav.exists() and all(packages.values())

    status = {
        "python": sys.version,
        "referenceVideo": str(reference_video),
        "referenceWav": str(reference_wav) if reference_wav.exists() else None,
        "ffmpeg": str(ffmpeg) if ffmpeg.exists() else None,
        "extract": extract,
        "nvidiaSmi": nvidia,
        "packages": packages,
        "voiceMode": "voxcpm" if ready else "fallback-tts",
        "voxcpmReady": ready,
    }
    status_out.write_text(json.dumps(status, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(status, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
