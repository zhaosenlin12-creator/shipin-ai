param(
  [string]$InputVideo = (Join-Path $PSScriptRoot '..\..\mp4\shuziren1.mp4'),
  [string]$OutputVideo = (Join-Path $PSScriptRoot '..\public\avatar-master.mp4')
)

$ErrorActionPreference = 'Stop'
$ffmpeg = Join-Path $PSScriptRoot '..\..\tools\facefusion\bin\ffmpeg.exe'
$outputDir = Split-Path -Parent $OutputVideo
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# The decoded source is already upright in FFmpeg. Center-crop its 16:9 frame to a portrait-safe 9:16 presenter shot.
& $ffmpeg -hide_banner -y -i $InputVideo `
  -vf "crop=1215:2160:(iw-1215)/2:0,scale=1080:1920:flags=lanczos,setsar=1" `
  -r 60 -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p $OutputVideo

if ($LASTEXITCODE -ne 0 -or -not (Test-Path $OutputVideo)) {
  throw "Presenter preprocessing failed: $OutputVideo"
}
