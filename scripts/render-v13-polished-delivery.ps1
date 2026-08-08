param(
  [string]$ProjectPath,
  [string]$AvatarSource,
  [string]$MixAudio,
  [string]$OutputVideo,
  [double]$AvatarLeadSeconds = 0.04,
  [int]$Fps = 60,
  [int]$TotalFrames = 2440,
  [string]$HyperFramesVersion = '0.7.87'
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $ProjectPath) { $ProjectPath = Join-Path $Root 'project\hyperframes-first180' }
if (-not $AvatarSource) { $AvatarSource = Join-Path $ProjectPath 'assets\avatar-ditto-v13h-natural.mp4' }
if (-not $MixAudio) {
  $mixCandidates = @(
    (Join-Path $Root 'local\final-approved-assets\_v13h_mix.wav'),
    (Join-Path $Root '_v13h_mix.wav')
  )
  $MixAudio = ($mixCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1)
  if (-not $MixAudio) { $MixAudio = $mixCandidates[0] }
}
if (-not $OutputVideo) { $OutputVideo = Join-Path $Root 'cartoon90-skill-v13natural-polished-delivery.mp4' }

$ProjectPath = (Resolve-Path $ProjectPath).Path
$AvatarSource = (Resolve-Path $AvatarSource).Path
$MixAudio = (Resolve-Path $MixAudio).Path
$OutputVideo = [IO.Path]::GetFullPath($OutputVideo)
$outDir = Split-Path -Parent $OutputVideo
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$ffprobe = (Get-Command ffprobe -ErrorAction Stop).Source

function Invoke-Native {
  param([string]$Exe, [string[]]$Arguments, [string]$Operation)
  & $Exe @Arguments
  if ($LASTEXITCODE -ne 0) { throw "$Operation failed with exit code $LASTEXITCODE." }
}

$avatarPolished = Join-Path $ProjectPath 'assets\avatar-head-polished.mp4'
$avatarHead = Join-Path $ProjectPath 'assets\avatar-head.mp4'
$avatarSynced = Join-Path $ProjectPath 'assets\avatar-head-synced.mp4'
$noAudio = Join-Path $ProjectPath 'output\cartoon-v13natural-polished-noaudio.mp4'

$trim = ('trim=start={0:0.###}' -f $AvatarLeadSeconds)
$filter = "$trim,setpts=PTS-STARTPTS,scale=168:-2,crop=168:196:0:28,hqdn3d=1:1:3:3,unsharp=3:3:0.28:3:3:0.0,tpad=stop_mode=clone:stop_duration=0.86,fps=$Fps,format=yuv420p"

Invoke-Native -Exe $ffmpeg -Arguments @(
  '-hide_banner','-y',
  '-i',$AvatarSource,
  '-vf',$filter,
  '-an',
  '-frames:v',[string]$TotalFrames,
  '-c:v','libx264',
  '-preset','slow',
  '-crf','15',
  '-bf','0',
  '-g','15',
  '-keyint_min','15',
  '-movflags','+faststart',
  $avatarPolished
) -Operation 'avatar polish'

Copy-Item -Force -Path $avatarPolished -Destination $avatarHead
Copy-Item -Force -Path $avatarPolished -Destination $avatarSynced

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
    [string]$Fps,
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
  '-i',$MixAudio,
  '-c:v','copy',
  '-c:a','aac',
  '-b:a','192k',
  '-shortest',
  '-movflags','+faststart',
  $OutputVideo
) -Operation 'mux final delivery'

$probe = & $ffprobe -v error -show_entries format=duration,size,bit_rate:stream=index,codec_type,width,height,r_frame_rate,avg_frame_rate,sample_rate,channels -of json $OutputVideo
if ($LASTEXITCODE -ne 0) { throw 'final ffprobe failed.' }

[pscustomobject]@{
  outputVideo = $OutputVideo
  noAudioVideo = $noAudio
  avatarPolished = $avatarPolished
  avatarLeadSeconds = $AvatarLeadSeconds
  fps = $Fps
  hyperframesVersion = $HyperFramesVersion
  media = $probe | ConvertFrom-Json
} | ConvertTo-Json -Depth 8
