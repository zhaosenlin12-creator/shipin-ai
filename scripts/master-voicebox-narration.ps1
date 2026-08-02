param(
  [Parameter(Mandatory = $true)][string]$InputAudio,
  [Parameter(Mandatory = $true)][string]$OutputAudio,
  [double]$TargetLufs = -15.0,
  [double]$TruePeak = -1.5,
  [double]$Lra = 7.0,
  [switch]$DisableDenoise
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ffmpeg = Join-Path $root 'tools\facefusion\bin\ffmpeg.exe'
if (-not (Test-Path $ffmpeg)) { throw "FFmpeg not found: $ffmpeg" }
if (-not (Test-Path $InputAudio)) { throw "Input audio not found: $InputAudio" }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputAudio) | Out-Null

$voiceCleanup = if ($DisableDenoise) {
  'anull'
} else {
  # Remove inherited low rumble and high hiss, then suppress the measured residual noise floor.
  'highpass=f=70:p=2,lowpass=f=10500:p=2,afftdn=nr=9:nf=-34:nt=w:om=o'
}

# FFmpeg reports harmless stream-layout hints on stderr. Native stderr must not
# become a PowerShell terminating error; the process exit code remains the gate.
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$firstPass = & $ffmpeg -hide_banner -i $InputAudio -af "$voiceCleanup,loudnorm=I=$TargetLufs`:TP=$TruePeak`:LRA=$Lra`:print_format=json" -f null NUL 2>&1
$firstExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
if ($firstExitCode -ne 0) { throw 'First loudnorm analysis failed.' }
$match = [regex]::Match(($firstPass -join "`n"), '(?s)\{\s*"input_i".*?\}')
if (-not $match.Success) { throw 'Unable to read first-pass loudnorm JSON.' }
$measure = $match.Value | ConvertFrom-Json
$filter = "$voiceCleanup,loudnorm=I=$TargetLufs`:TP=$TruePeak`:LRA=$Lra`:measured_I=$($measure.input_i)`:measured_TP=$($measure.input_tp)`:measured_LRA=$($measure.input_lra)`:measured_thresh=$($measure.input_thresh)`:offset=$($measure.target_offset)`:linear=true:print_format=summary"

$ErrorActionPreference = 'Continue'
& $ffmpeg -hide_banner -y -i $InputAudio -af $filter -ar 48000 -c:a pcm_s16le $OutputAudio
$secondExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
if ($secondExitCode -ne 0) { throw 'Second loudnorm pass failed.' }
Get-Item $OutputAudio | Select-Object FullName,Length,LastWriteTime | ConvertTo-Json
