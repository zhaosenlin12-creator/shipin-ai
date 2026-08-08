param(
  [string]$ProjectPath,
  [string]$OutputVideo,
  [string]$Voice = 'zh-CN-YunxiNeural',
  [string]$Rate = '+18%',
  [double]$SpeechDuration = 39.868125,
  [double]$FinalDuration = 40.656,
  [double]$AvatarLeadSeconds = 0.04,
  [string]$PythonPath,
  [switch]$SkipAvatar,
  [string]$HyperFramesVersion = '0.7.87'
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $ProjectPath) { $ProjectPath = Join-Path $Root 'project\hyperframes-douyin-codex-novel' }
if (-not $OutputVideo) { $OutputVideo = Join-Path $Root 'douyin-codex-novel-skill-replica.mp4' }

$ProjectPath = (Resolve-Path $ProjectPath).Path
$OutputVideo = [IO.Path]::GetFullPath($OutputVideo)
$Assets = Join-Path $ProjectPath 'assets'
$Out = Join-Path $ProjectPath 'output'
$Verify = Join-Path $Out 'verification'
New-Item -ItemType Directory -Force -Path $Assets,$Out,$Verify | Out-Null

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$ffprobe = (Get-Command ffprobe -ErrorAction Stop).Source
if (-not $PythonPath) {
  $python310 = 'C:\Users\Administrator\AppData\Local\Programs\Python\Python310\python.exe'
  if (Test-Path $python310) { $PythonPath = $python310 }
}

function Invoke-Native {
  param([string]$Exe, [string[]]$Arguments, [string]$Operation)
  & $Exe @Arguments
  if ($LASTEXITCODE -ne 0) { throw "$Operation failed with exit code $LASTEXITCODE." }
}

function Get-DurationSeconds {
  param([string]$Path)
  $value = & $ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 $Path
  if ($LASTEXITCODE -ne 0) { throw "ffprobe duration failed: $Path" }
  return [double]::Parse(($value | Select-Object -First 1), [Globalization.CultureInfo]::InvariantCulture)
}

$textPath = Join-Path $Assets 'narration-codex-novel.txt'
$ttsMp3 = Join-Path $Out 'narration-edge-raw.mp3'
$speechWav = Join-Path $Out 'narration-codex-novel.wav'
$mixWav = Join-Path $Out 'mix-codex-novel.wav'
$bgmCandidates = @(
  (Join-Path $Root 'local\final-approved-assets\_v13h_bgm.wav'),
  (Join-Path $Root '_v13h_bgm.wav')
)
$bgmWav = ($bgmCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1)

Invoke-Native -Exe 'edge-tts' -Arguments @(
  '--voice',$Voice,
  '--rate',$Rate,
  '--file',$textPath,
  '--write-media',$ttsMp3
) -Operation 'Edge TTS narration'

$rawDuration = Get-DurationSeconds $ttsMp3
$atempo = $rawDuration / $SpeechDuration
$atempoText = $atempo.ToString('0.######', [Globalization.CultureInfo]::InvariantCulture)
$speechDurationText = $SpeechDuration.ToString('0.######', [Globalization.CultureInfo]::InvariantCulture)
$finalDurationText = $FinalDuration.ToString('0.######', [Globalization.CultureInfo]::InvariantCulture)

Invoke-Native -Exe $ffmpeg -Arguments @(
  '-hide_banner','-y',
  '-i',$ttsMp3,
  '-af',"aresample=48000,atempo=$atempoText,apad,atrim=0:$speechDurationText",
  '-ac','1',
  '-c:a','pcm_s16le',
  $speechWav
) -Operation 'narration duration fit'

if ($bgmWav -and (Test-Path $bgmWav)) {
  Invoke-Native -Exe $ffmpeg -Arguments @(
    '-hide_banner','-y',
    '-i',$speechWav,
    '-stream_loop','-1',
    '-i',$bgmWav,
    '-filter_complex',"[0:a]apad,atrim=0:$finalDurationText,volume=1.0[a0];[1:a]atrim=0:$finalDurationText,volume=0.20[a1];[a0][a1]amix=inputs=2:duration=first:dropout_transition=0,alimiter=limit=0.95",
    '-ar','48000',
    '-ac','2',
    '-c:a','pcm_s16le',
    $mixWav
  ) -Operation 'narration music mix'
} else {
  Invoke-Native -Exe $ffmpeg -Arguments @(
    '-hide_banner','-y',
    '-i',$speechWav,
    '-af',"apad,atrim=0:$finalDurationText",
    '-ar','48000',
    '-ac','2',
    '-c:a','pcm_s16le',
    $mixWav
  ) -Operation 'narration mix without bgm'
}

$avatarDitto = Join-Path $Assets 'avatar-ditto-natural.mp4'
$avatarHead = Join-Path $Assets 'avatar-head.mp4'
$syncStatus = Join-Path $Verify 'avatar-ditto-sync.json'
$sourceFace = Join-Path $Root 'project\hyperframes-first180\assets\_face_source.png'

if (-not $SkipAvatar) {
  $dittoArgs = @(
    '-NoProfile',
    '-ExecutionPolicy','Bypass',
    '-File',(Join-Path $Root 'scripts\run-ditto-avatar.ps1'),
    '-AudioPath',$speechWav,
    '-SourceImage',$sourceFace,
    '-OutputVideo',$avatarDitto,
    '-OutputFps','60',
    '-SyncStatusOutput',$syncStatus
  )
  if ($PythonPath) { $dittoArgs += @('-PythonPath',$PythonPath) }
  Invoke-Native -Exe 'powershell.exe' -Arguments $dittoArgs -Operation 'Ditto synced avatar render'
}

if (-not (Test-Path $avatarDitto)) {
  $fallback = Join-Path $Root 'project\hyperframes-first180\assets\avatar-ditto-v13h-natural.mp4'
  if (-not (Test-Path $fallback)) { throw "Missing avatar source: $avatarDitto" }
  Copy-Item -Force $fallback $avatarDitto
}

$totalFrames = [int][Math]::Ceiling($FinalDuration * 60)
$trim = ('trim=start={0:0.###}' -f $AvatarLeadSeconds)
$filter = "$trim,setpts=PTS-STARTPTS,scale=168:-2,crop=168:196:0:28,hqdn3d=1:1:3:3,unsharp=3:3:0.28:3:3:0.0,tpad=stop_mode=clone:stop_duration=1.0,fps=60,format=yuv420p"

Invoke-Native -Exe $ffmpeg -Arguments @(
  '-hide_banner','-y',
  '-i',$avatarDitto,
  '-vf',$filter,
  '-an',
  '-frames:v',[string]$totalFrames,
  '-c:v','libx264',
  '-preset','slow',
  '-crf','15',
  '-bf','0',
  '-g','15',
  '-keyint_min','15',
  '-movflags','+faststart',
  $avatarHead
) -Operation 'small avatar polish'

$noAudio = Join-Path $Out 'douyin-codex-novel-noaudio.mp4'
Push-Location $ProjectPath
try {
  Invoke-Native -Exe 'npx' -Arguments @(
    '--yes',
    "hyperframes@$HyperFramesVersion",
    'render',
    '.',
    '--output',
    $noAudio,
    '--fps',
    '60',
    '--quality',
    'high'
  ) -Operation 'HyperFrames render'
}
finally {
  Pop-Location
}

Invoke-Native -Exe $ffmpeg -Arguments @(
  '-hide_banner','-y',
  '-i',$noAudio,
  '-i',$mixWav,
  '-c:v','copy',
  '-c:a','aac',
  '-b:a','192k',
  '-shortest',
  '-movflags','+faststart',
  $OutputVideo
) -Operation 'mux final replica'

$probe = & $ffprobe -v error -show_entries format=duration,size,bit_rate:stream=index,codec_type,width,height,r_frame_rate,avg_frame_rate,sample_rate,channels -of json $OutputVideo
if ($LASTEXITCODE -ne 0) { throw 'final ffprobe failed.' }

[pscustomobject]@{
  outputVideo = $OutputVideo
  projectPath = $ProjectPath
  rawTtsDuration = $rawDuration
  speechDuration = Get-DurationSeconds $speechWav
  finalDuration = Get-DurationSeconds $OutputVideo
  atempo = $atempo
  avatar = $avatarHead
  syncStatus = $syncStatus
  media = $probe | ConvertFrom-Json
} | ConvertTo-Json -Depth 8
