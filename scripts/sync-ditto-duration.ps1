param(
  [Parameter(Mandatory = $true)][string]$InputVideo,
  [Parameter(Mandatory = $true)][string]$ReferenceAudio,
  [Parameter(Mandatory = $true)][string]$OutputVideo,
  [string]$FfmpegPath,
  [string]$FfprobePath,
  [int]$OutputFps = 60,
  [double]$DriftToleranceSeconds = 0.08,
  [string]$StatusOutput,
  [switch]$VideoOnly,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Resolve-NativeTool {
  param([string]$ExplicitPath, [string]$ToolName)

  if ($ExplicitPath) {
    if (-not (Test-Path $ExplicitPath)) { throw "Required tool is missing: $ExplicitPath" }
    return (Resolve-Path $ExplicitPath).Path
  }

  $bundled = Join-Path $root "tools\facefusion\bin\$ToolName.exe"
  if (Test-Path $bundled) { return (Resolve-Path $bundled).Path }

  $cmd = Get-Command $ToolName -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  throw "Could not find $ToolName. Pass -$($ToolName.Substring(0,1).ToUpperInvariant())$($ToolName.Substring(1))Path explicitly."
}

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

function Convert-FromInvariant {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) { return 0.0 }
  return [double]::Parse($Value.Trim(), $InvariantCulture)
}

function Convert-ToInvariant {
  param([double]$Value)

  return $Value.ToString('0.######', $InvariantCulture)
}

function Get-FormatDuration {
  param([string]$Ffprobe, [string]$Path)

  $raw = & $Ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 $Path
  if ($LASTEXITCODE -ne 0) { throw "ffprobe failed for $Path" }
  return Convert-FromInvariant ($raw | Select-Object -First 1)
}

$ffmpeg = Resolve-NativeTool -ExplicitPath $FfmpegPath -ToolName 'ffmpeg'
$ffprobe = Resolve-NativeTool -ExplicitPath $FfprobePath -ToolName 'ffprobe'
$input = (Resolve-Path $InputVideo).Path
$audio = (Resolve-Path $ReferenceAudio).Path
$output = [IO.Path]::GetFullPath($OutputVideo)
$outDir = Split-Path -Parent $output
if ($outDir) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$videoDuration = Get-FormatDuration -Ffprobe $ffprobe -Path $input
$audioDuration = Get-FormatDuration -Ffprobe $ffprobe -Path $audio
if ($videoDuration -le 0) { throw "Input video has invalid duration: $videoDuration" }
if ($audioDuration -le 0) { throw "Reference audio has invalid duration: $audioDuration" }

$drift = $videoDuration - $audioDuration
$absDrift = [Math]::Abs($drift)
$speedFactor = $videoDuration / $audioDuration
$ptsRatio = $audioDuration / $videoDuration
$needsSync = $Force -or ($absDrift -gt $DriftToleranceSeconds)

if (-not $needsSync) {
  if ($input -ne $output) {
    Copy-Item -LiteralPath $input -Destination $output -Force
  }

  $status = [pscustomobject]@{
    inputVideo = $input
    referenceAudio = $audio
    outputVideo = $output
    videoDuration = [Math]::Round($videoDuration, 6)
    audioDuration = [Math]::Round($audioDuration, 6)
    driftSeconds = [Math]::Round($drift, 6)
    speedFactor = [Math]::Round($speedFactor, 6)
    synced = $false
    reason = 'within-tolerance'
  }
  if ($StatusOutput) {
    $statusDir = Split-Path -Parent ([IO.Path]::GetFullPath($StatusOutput))
    if ($statusDir) { New-Item -ItemType Directory -Force -Path $statusDir | Out-Null }
    $status | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -Path $StatusOutput
  }
  $status | ConvertTo-Json -Depth 5
  exit 0
}

$targetText = Convert-ToInvariant $audioDuration
$ptsText = Convert-ToInvariant $ptsRatio
$filter = "setpts=$ptsText*PTS,fps=$OutputFps"
$tempOutput = $output
if ($input -eq $output) {
  $tempOutput = Join-Path $outDir (([IO.Path]::GetFileNameWithoutExtension($output)) + '.duration-sync.tmp.mp4')
}

$args = @('-hide_banner','-y','-i',$input)
if (-not $VideoOnly) { $args += @('-i',$audio) }
$args += @('-map','0:v:0','-filter:v',$filter,'-t',$targetText,'-c:v','libx264','-pix_fmt','yuv420p','-preset','fast','-crf','18')
if ($VideoOnly) {
  $args += @('-an')
}
else {
  $args += @('-map','1:a:0','-c:a','aac','-ar','48000','-ac','2','-b:a','160k','-shortest')
}
$args += @('-movflags','+faststart',$tempOutput)

Invoke-Native -Exe $ffmpeg -Arguments $args -Operation 'Ditto duration sync'

if ($tempOutput -ne $output) {
  Move-Item -LiteralPath $tempOutput -Destination $output -Force
}

$finalDuration = Get-FormatDuration -Ffprobe $ffprobe -Path $output
$status = [pscustomobject]@{
  inputVideo = $input
  referenceAudio = $audio
  outputVideo = $output
  videoDuration = [Math]::Round($videoDuration, 6)
  audioDuration = [Math]::Round($audioDuration, 6)
  outputDuration = [Math]::Round($finalDuration, 6)
  driftSeconds = [Math]::Round($drift, 6)
  speedFactor = [Math]::Round($speedFactor, 6)
  ptsRatio = [Math]::Round($ptsRatio, 6)
  outputFps = $OutputFps
  videoOnly = [bool]$VideoOnly
  synced = $true
  rule = 'video setpts = referenceAudioDuration / inputVideoDuration; original mastered audio remains the timing authority'
}

if ($StatusOutput) {
  $statusDir = Split-Path -Parent ([IO.Path]::GetFullPath($StatusOutput))
  if ($statusDir) { New-Item -ItemType Directory -Force -Path $statusDir | Out-Null }
  $status | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -Path $StatusOutput
}
$status | ConvertTo-Json -Depth 5
