$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ffmpeg = Join-Path $root 'tools\facefusion\bin\ffmpeg.exe'
$assets = Join-Path $root 'project\hyperframes-first120\assets'
$runner = Join-Path $PSScriptRoot 'run-avatar-wav2lip.ps1'
$work = Join-Path $root 'project\hyperframes-first120\.render-work\wav2lip'

foreach ($path in @($ffmpeg, $assets, $runner)) {
  if (-not (Test-Path $path)) { throw "Required path is missing: $path" }
}
New-Item -ItemType Directory -Force $work | Out-Null

$narration = Join-Path $assets 'narration.wav'
$earlyAudio = Join-Path $work 'narration-0-40.wav'
$lateAudio = Join-Path $work 'narration-92-120.wav'

& $ffmpeg -hide_banner -loglevel error -y -ss 0 -t 40 -i $narration -c:a pcm_s16le $earlyAudio
if ($LASTEXITCODE -ne 0) { throw 'Failed to make early narration audio.' }
& $ffmpeg -hide_banner -loglevel error -y -ss 92 -t 28 -i $narration -c:a pcm_s16le $lateAudio
if ($LASTEXITCODE -ne 0) { throw 'Failed to make late narration audio.' }

& $runner -AudioPath $earlyAudio -TargetVideo (Join-Path $assets 'avatar-gesture-0-40.mp4') -OutputVideo (Join-Path $assets 'avatar-wav2lip-0-40.mp4') -TempPath (Join-Path $work 'early')
& $runner -AudioPath $lateAudio -TargetVideo (Join-Path $assets 'avatar-gesture-92-120.mp4') -OutputVideo (Join-Path $assets 'avatar-wav2lip-92-120.mp4') -TempPath (Join-Path $work 'late')

Get-Item (Join-Path $assets 'avatar-wav2lip-0-40.mp4'),(Join-Path $assets 'avatar-wav2lip-92-120.mp4') |
  Select-Object FullName,Length,LastWriteTime |
  ConvertTo-Json
