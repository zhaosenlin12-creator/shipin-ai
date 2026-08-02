param(
  [string]$ModelId = 'Qwen/Qwen3-TTS-12Hz-0.6B-Base',
  [string]$CacheDir = 'C:\kaifa_senlin\shipin-ai\tools\voicebox\model-cache',
  [string]$Mirror = 'https://hf-mirror.com'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$python = Join-Path $root 'tools\voicebox\.venv\Scripts\python.exe'

if (-not (Test-Path $python)) { throw "Voicebox Python environment not found: $python" }
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null

$env:HF_HOME = $CacheDir
$env:HF_ENDPOINT = $Mirror

$code = @'
import os
from huggingface_hub import snapshot_download

path = snapshot_download(
    repo_id=os.environ['VOICEBOX_QWEN_MODEL_ID'],
    cache_dir=os.environ['HF_HOME'],
    resume_download=True,
)
print(path)
'@

$env:VOICEBOX_QWEN_MODEL_ID = $ModelId
& $python -c $code
if ($LASTEXITCODE -ne 0) { throw "Qwen model download failed with exit code $LASTEXITCODE" }
