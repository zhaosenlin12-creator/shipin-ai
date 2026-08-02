$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = Join-Path $root 'project\hyperframes-first120'
$bin = Join-Path $root 'tools\facefusion\bin'
$output = Join-Path $project 'output\first120-hyperframes-wav2lip-final.mp4'

$env:PATH = "$bin;$env:PATH"
$env:HYPERFRAMES_FFMPEG_PATH = Join-Path $bin 'ffmpeg.exe'
$env:HYPERFRAMES_FFPROBE_PATH = Join-Path $bin 'ffprobe.exe'

Push-Location $project
try {
  & 'C:\Program Files\nodejs\npx.cmd' --yes hyperframes@0.7.87 render --output $output --fps 60 --quality high --workers 4
  if ($LASTEXITCODE -ne 0) { throw "HyperFrames render failed with exit code $LASTEXITCODE" }
}
finally {
  Pop-Location
}
