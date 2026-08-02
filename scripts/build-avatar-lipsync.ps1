$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ffmpeg = Join-Path $root 'tools\facefusion\bin\ffmpeg.exe'
$facefusionPython = Join-Path $root 'tools\facefusion\.venv-cuda-py310\Scripts\python.exe'
$facefusionLauncher = Join-Path $root 'scripts\run-facefusion-gpu.py'
$project = Join-Path $root 'project'
$public = Join-Path $project 'public'
$generated = Join-Path $public 'generated'
$audio = Join-Path $public 'narration-mastered.wav'
$outputs = Join-Path $project 'output\avatar-lipsync'

New-Item -ItemType Directory -Force -Path $outputs,$generated | Out-Null
if (-not (Test-Path $ffmpeg)) { throw "FFmpeg not found: $ffmpeg" }
if (-not (Test-Path $facefusionPython)) { throw "CUDA FaceFusion Python not found: $facefusionPython" }
if (-not (Test-Path $audio)) { throw "Mastered narration not found: $audio" }

$segments = @(
  @{ Name = '0-60'; Target = 'presenter-neutral-loop-60.mp4'; Start = 0; Duration = 60 },
  @{ Name = '60-120'; Target = 'presenter-yaw-left-loop-60.mp4'; Start = 60; Duration = 60 }
)

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
  foreach ($segment in $segments) {
    $target = Join-Path $generated $segment.Target
    $audioSegment = Join-Path $outputs ("narration-{0}.wav" -f $segment.Name)
    $rawOutput = Join-Path $outputs ("avatar-lipsync-{0}-raw.mp4" -f $segment.Name)
    $finalOutput = Join-Path $generated ("avatar-lipsync-{0}.mp4" -f $segment.Name)

    $nativeErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $ffmpeg -hide_banner -y -ss $segment.Start -t $segment.Duration -i $audio -ac 1 -ar 16000 -c:a pcm_s16le $audioSegment 2>$null
    $ffmpegExitCode = $LASTEXITCODE
    $ErrorActionPreference = $nativeErrorPreference
    if ($ffmpegExitCode -ne 0) { throw "Audio segment failed: $audioSegment" }

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
        --log-level info *> (Join-Path $outputs ("facefusion-{0}.log" -f $segment.Name))
      $facefusionExitCode = $LASTEXITCODE
      $ErrorActionPreference = $nativeErrorPreference
      if ($facefusionExitCode -ne 0) { throw "FaceFusion lip sync failed: $($segment.Name)" }
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
    if ($ffmpegExitCode -ne 0 -or -not (Test-Path $finalOutput)) { throw "Mux failed: $finalOutput" }
  }
}
finally {
  $env:PATH = $oldPath
}

Write-Output (Get-ChildItem $generated -Filter 'avatar-lipsync-*.mp4' | Select-Object FullName,Length,LastWriteTime | ConvertTo-Json)
