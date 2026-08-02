param(
  [string]$Timeline = (Join-Path $PSScriptRoot '..\timeline\source-style-first120.json'),
  [string]$OutputAudio = (Join-Path $PSScriptRoot '..\public\narration.wav'),
  [string]$OutputSubtitles = (Join-Path $PSScriptRoot '..\public\narration.srt'),
  [string]$Voice = 'zh-CN-YunjianNeural'
)

$ErrorActionPreference = 'Stop'
$timelineObject = Get-Content -Raw -Encoding UTF8 $Timeline | ConvertFrom-Json
$audioDir = Join-Path $PSScriptRoot '..\audio\segments'
$publicDir = Split-Path -Parent $OutputAudio
$ffmpeg = Join-Path $PSScriptRoot '..\..\tools\facefusion\bin\ffmpeg.exe'
New-Item -ItemType Directory -Force -Path $audioDir,$publicDir | Out-Null

$segmentFiles = @()
$srtBlocks = @()
$sceneIndex = 0
foreach ($scene in $timelineObject.scenes) {
  $sceneIndex++
  $segment = Join-Path $audioDir ("scene-{0:D2}.mp3" -f $sceneIndex)
  $sceneText = [string]$scene.caption.zh
  & edge-tts -t $sceneText -v $Voice --rate '+8%' --volume '+0%' --write-media $segment
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $segment)) {
    throw "TTS failed for $($scene.id)"
  }
  $segmentFiles += $segment
  $start = [double]$scene.start
  $end = $start + [double]$scene.duration
  $startSrt = [TimeSpan]::FromSeconds($start).ToString('hh\:mm\:ss\,fff')
  $endSrt = [TimeSpan]::FromSeconds($end).ToString('hh\:mm\:ss\,fff')
  $srtBlocks += "$sceneIndex`r`n$startSrt --> $endSrt`r`n$sceneText`r`n"
}

$inputs = @()
$filters = @()
for ($i = 0; $i -lt $segmentFiles.Count; $i++) {
  $inputs += @('-i', $segmentFiles[$i])
  $delayMs = [int]([double]$timelineObject.scenes[$i].start * 1000)
  $sceneDuration = [double]$timelineObject.scenes[$i].duration
  $filters += "[$i`:a]atrim=duration=$sceneDuration,asetpts=PTS-STARTPTS,adelay=${delayMs}|${delayMs}[a$i]"
}
$mixInputs = -join (0..($segmentFiles.Count - 1) | ForEach-Object { "[a$_]" })
$filterComplex = ($filters -join ';') + ";${mixInputs}amix=inputs=$($segmentFiles.Count):duration=longest:dropout_transition=0,aresample=48000,apad=whole_dur=$($timelineObject.targetDurationSeconds),alimiter=limit=0.95[out]"

& $ffmpeg -hide_banner -y @inputs -filter_complex $filterComplex -map '[out]' -t $timelineObject.targetDurationSeconds -c:a pcm_s16le $OutputAudio
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $OutputAudio)) {
  throw "Narration mix failed: $OutputAudio"
}
[IO.File]::WriteAllText($OutputSubtitles, ($srtBlocks -join "`r`n"), [Text.Encoding]::UTF8)
