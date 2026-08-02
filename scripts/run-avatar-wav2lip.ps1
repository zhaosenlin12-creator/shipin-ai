param(
  [Parameter(Mandatory = $true)]
  [string]$AudioPath,
  [Parameter(Mandatory = $true)]
  [string]$TargetVideo,
  [Parameter(Mandatory = $true)]
  [string]$OutputVideo,
  [string]$TempPath
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$faceFusion = Join-Path $root 'tools\facefusion'
$venv = Join-Path $faceFusion '.venv-cuda-py310'
$python = Join-Path $venv 'Scripts\python.exe'
$ffmpegBin = Join-Path $faceFusion 'bin'

foreach ($path in @($AudioPath, $TargetVideo, $python, $ffmpegBin)) {
  if (-not (Test-Path $path)) { throw "Required path is missing: $path" }
}

$outputDirectory = Split-Path -Parent $OutputVideo
if (-not $outputDirectory) { throw 'OutputVideo must include a directory.' }
New-Item -ItemType Directory -Force $outputDirectory | Out-Null

if (-not $TempPath) {
  $TempPath = Join-Path $outputDirectory '.facefusion-temp'
}
New-Item -ItemType Directory -Force $TempPath | Out-Null

$cudaBins = Get-ChildItem -LiteralPath (Join-Path $venv 'Lib\site-packages\nvidia') -Directory -ErrorAction SilentlyContinue |
  ForEach-Object { Join-Path $_.FullName 'bin' } |
  Where-Object { Test-Path $_ }

if (-not $cudaBins) { throw 'CUDA runtime folders were not found in the FaceFusion environment.' }
$env:PATH = "$ffmpegBin;$($cudaBins -join ';');$env:PATH"

$configPath = Join-Path $TempPath 'facefusion-wav2lip.ini'
@'
[face_selector]
face_selector_mode = one

[output_creation]
output_audio_encoder = aac
output_audio_quality = 90
output_video_encoder = libx264
output_video_preset = medium
output_video_quality = 92
output_video_fps = 30

[processors]
processors = lip_syncer
lip_syncer_model = wav2lip_96
lip_syncer_weight = 1.0

[execution]
execution_providers = cuda
execution_thread_count = 4
execution_queue_count = 1

[memory]
video_memory_strategy = strict
'@ | Set-Content -LiteralPath $configPath -Encoding ascii

Push-Location $faceFusion
try {
  & $python '.\facefusion.py' headless-run `
    --config-path $configPath `
    --temp-path $TempPath `
    -s $AudioPath `
    -t $TargetVideo `
    -o $OutputVideo `
    --log-level info
  if ($LASTEXITCODE -ne 0) { throw "FaceFusion failed with exit code $LASTEXITCODE" }
}
finally {
  Pop-Location
}
