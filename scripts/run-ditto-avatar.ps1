param(
  [Parameter(Mandatory = $true)][string]$AudioPath,
  [Parameter(Mandatory = $true)][string]$OutputVideo,
  [string]$SourceImage,
  [string]$PythonPath,
  [string]$DataRoot,
  [string]$ConfigPath,
  [string]$DittoRoot,
  [string]$FfmpegPath,
  [string]$FfprobePath
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$defaultDitto = Join-Path $root 'vendor\ditto-talkinghead'
if (-not (Test-Path $defaultDitto)) { $defaultDitto = Join-Path $root 'tools\ditto-talkinghead' }
$ditto = if ($DittoRoot) { $DittoRoot } else { $defaultDitto }
$ffmpeg = if ($FfmpegPath) { $FfmpegPath } else { Join-Path $root 'tools\facefusion\bin\ffmpeg.exe' }
$ffprobe = if ($FfprobePath) { $FfprobePath } else { Join-Path $root 'tools\facefusion\bin\ffprobe.exe' }

if (-not $SourceImage) { $SourceImage = Join-Path $root 'project\public\generated\presenter-user-avatar-neutral.png' }
if (-not $PythonPath) { $PythonPath = Join-Path $ditto '.venv\Scripts\python.exe' }
if (-not $DataRoot) { $DataRoot = Join-Path $ditto 'checkpoints\ditto_pytorch' }
if (-not $ConfigPath) { $ConfigPath = Join-Path $ditto 'checkpoints\ditto_cfg\v0.4_hubert_cfg_pytorch.pkl' }

function Invoke-Native {
  param([string]$Exe, [string[]]$Arguments, [string]$Operation)

  $previous = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    & $Exe @Arguments
    $exitCode = $LASTEXITCODE
  }
  finally {
    $ErrorActionPreference = $previous
  }
  if ($exitCode -ne 0) { throw "$Operation failed with exit code $exitCode." }
}

foreach ($path in @($ditto, $ffmpeg, $ffprobe, $AudioPath, $SourceImage, $PythonPath, $DataRoot, $ConfigPath)) {
  if (-not (Test-Path $path)) { throw "Required Ditto asset is missing: $path" }
}

$source = (Resolve-Path $SourceImage).Path
$forbidden = @('shuziren1.mp4', '数字人.mp4', '9e61c373398f12c4179ae3a2ba24060b_raw.mp4')
if ([IO.Path]::GetExtension($source).ToLowerInvariant() -notin @('.png', '.jpg', '.jpeg')) {
  throw 'Ditto source must be a generated presenter image, never a raw avatar video.'
}
if ($forbidden | Where-Object { $source.EndsWith($_, [StringComparison]::OrdinalIgnoreCase) }) {
  throw 'Raw approved reference footage is not permitted in the final avatar render.'
}

$output = [IO.Path]::GetFullPath($OutputVideo)
$outDir = Split-Path -Parent $output
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$audio16k = Join-Path $outDir (([IO.Path]::GetFileNameWithoutExtension($output)) + '-ditto-16k.wav')

# Ditto extracts HuBERT features at 16 kHz. Keep the original mastered WAV untouched.
Invoke-Native -Exe $ffmpeg -Arguments @('-hide_banner','-y','-i',$AudioPath,'-map','0:a:0','-ac','1','-ar','16000','-c:a','pcm_s16le',$audio16k) -Operation 'Ditto audio preparation'
Invoke-Native -Exe $PythonPath -Arguments @('-c','import torch; assert torch.cuda.is_available(), "CUDA is required for Ditto"; print(torch.cuda.get_device_name(0))') -Operation 'Ditto CUDA preflight'

$oldPath = $env:PATH
$env:PATH = "$(Split-Path $ffmpeg);$oldPath"
try {
  Push-Location $ditto
  try {
    Invoke-Native -Exe $PythonPath -Arguments @(
      'inference.py',
      '--data_root',$DataRoot,
      '--cfg_pkl',$ConfigPath,
      '--audio_path',$audio16k,
      '--source_path',$source,
      '--output_path',$output
    ) -Operation 'Ditto audio-driven avatar render'
  }
  finally {
    Pop-Location
  }
}
finally {
  $env:PATH = $oldPath
}

if (-not (Test-Path $output)) { throw "Ditto did not write an output video: $output" }
$probe = & $ffprobe -v error -show_entries format=duration:stream=codec_type,codec_name,width,height,r_frame_rate -of json $output
if ($LASTEXITCODE -ne 0) { throw 'Ditto output validation failed.' }
[pscustomobject]@{
  output = $output
  preparedAudio = $audio16k
  media = $probe | ConvertFrom-Json
} | ConvertTo-Json -Depth 6
