$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ffmpeg = Join-Path $root 'tools\facefusion\bin\ffmpeg.exe'
$facefusionPython = Join-Path $root 'tools\facefusion\.venv-cuda-py310\Scripts\python.exe'
$facefusionLauncher = Join-Path $root 'scripts\run-facefusion-gpu.py'
$project = Join-Path $root 'project'
$generated = Join-Path $project 'public\generated'
$outDir = Join-Path $project 'output\avatar-lipsync'
$audio = Join-Path $project 'public\narration-mastered.wav'
$target = Join-Path $outDir 'presenter-late-target-28s.mp4'
$audioSegment = Join-Path $outDir 'narration-92-120.wav'
$rawOutput = Join-Path $outDir 'avatar-lipsync-92-120-raw.mp4'
$finalOutput = Join-Path $generated 'avatar-lipsync-92-120.mp4'

New-Item -ItemType Directory -Force -Path $outDir,$generated | Out-Null
if (-not (Test-Path $ffmpeg)) { throw "FFmpeg not found: $ffmpeg" }
if (-not (Test-Path $facefusionPython)) { throw "CUDA FaceFusion Python not found: $facefusionPython" }
if (-not (Test-Path $audio)) { throw "Mastered narration not found: $audio" }

$nativeErrorPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $ffmpeg -hide_banner -y -t 28 -i (Join-Path $generated 'presenter-yaw-left-loop-60.mp4') -an -c:v libx264 -preset medium -crf 18 $target 2>$null
$ffmpegExitCode = $LASTEXITCODE
$ErrorActionPreference = $nativeErrorPreference
if ($ffmpegExitCode -ne 0) { throw "Late presenter target build failed: $target" }

$nativeErrorPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $ffmpeg -hide_banner -y -ss 92 -t 28 -i $audio -ac 1 -ar 16000 -c:a pcm_s16le $audioSegment 2>$null
$ffmpegExitCode = $LASTEXITCODE
$ErrorActionPreference = $nativeErrorPreference
if ($ffmpegExitCode -ne 0) { throw "Late audio extraction failed: $audioSegment" }

$oldPath = $env:PATH
$cudaSite = Join-Path $root 'tools\facefusion\.venv-cuda-py310\Lib\site-packages'
$cudaBins = @(
  (Join-Path $cudaSite 'nvidia\cublas\bin'),
  (Join-Path $cudaSite 'nvidia\cuda_runtime\bin'),
  (Join-Path $cudaSite 'nvidia\cudnn\bin'),
  (Join-Path $cudaSite 'nvidia\cufft\bin'),
  (Join-Path $cudaSite 'nvidia\nvjitlink\bin')
)
$env:PATH = (($cudaBins -join ';') + ";$(Split-Path $ffmpeg);$oldPath")

try {
  Remove-Item -LiteralPath $rawOutput,$finalOutput -Force -ErrorAction SilentlyContinue
  Push-Location (Join-Path $root 'tools\facefusion')
  try {
    $nativeErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $facefusionPython $facefusionLauncher headless-run `
      --source-paths $audioSegment `
      --target-path $target `
      --output-path $rawOutput `
      --processors lip_syncer `
      --lip-syncer-model edtalk_256 `
      --lip-syncer-weight 0.85 `
      --face-selector-mode one `
      --execution-providers cuda `
      --execution-device-id 0 `
      --execution-queue-count 1 `
      --video-memory-strategy strict `
      --output-video-resolution 1280x720 `
      --output-video-fps 30 `
      --output-video-quality 95 `
      --log-level info *> (Join-Path $outDir 'facefusion-92-120.log')
    $facefusionExitCode = $LASTEXITCODE
    $ErrorActionPreference = $nativeErrorPreference
    if ($facefusionExitCode -ne 0) { throw 'Late FaceFusion lip sync failed' }
  }
  finally {
    Pop-Location
  }

  $nativeErrorPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  & $ffmpeg -hide_banner -y -i $rawOutput -i $audioSegment `
    -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -ar 48000 `
    -af "loudnorm=I=-16:TP=-1.5:LRA=11" -movflags +faststart $finalOutput 2>$null
  $ffmpegExitCode = $LASTEXITCODE
  $ErrorActionPreference = $nativeErrorPreference
  if ($ffmpegExitCode -ne 0 -or -not (Test-Path $finalOutput)) { throw "Late mux failed: $finalOutput" }
}
finally {
  $env:PATH = $oldPath
}

Write-Output $finalOutput
