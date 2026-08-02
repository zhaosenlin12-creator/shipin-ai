param(
  [string]$InputVideo = "$PSScriptRoot\..\output\rendered\source-style-first120.mp4",
  [string]$ReportPath = "$PSScriptRoot\..\output\verification\source-style-validation-report.json"
)

$ErrorActionPreference = 'Stop'
$ffmpeg = 'C:\kaifa_senlin\shipin-ai\tools\facefusion\bin\ffmpeg.exe'

if (-not (Test-Path -LiteralPath $ffmpeg)) {
  throw "FFmpeg was not found: $ffmpeg"
}
if (-not (Test-Path -LiteralPath $InputVideo)) {
  throw "Input video was not found: $InputVideo"
}

function Invoke-Ffmpeg {
  param([string[]]$Arguments)
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $ffmpeg
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.RedirectStandardError = $true
  $psi.RedirectStandardOutput = $true
  $psi.Arguments = (($Arguments | ForEach-Object {
    if ($_ -match '[\s"]') { '"' + $_.Replace('"', '\"') + '"' } else { $_ }
  }) -join ' ')
  $process = New-Object System.Diagnostics.Process
  $process.StartInfo = $psi
  [void]$process.Start()
  $stdout = $process.StandardOutput.ReadToEnd()
  $stderr = $process.StandardError.ReadToEnd()
  $process.WaitForExit()
  $exitCode = $process.ExitCode
  $process.Dispose()
  [pscustomobject]@{
    output = ($stdout + "`n" + $stderr)
    exitCode = $exitCode
  }
}

function Get-MediaProbe {
  param([string]$Path)
  $result = Invoke-Ffmpeg -Arguments @('-hide_banner', '-i', $Path)
  $joined = (($result.output -split "`r?`n") -join ' ') -replace '\s+', ' '
  $durationMatch = [regex]::Match($joined, 'Duration:\s+(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)')
  $videoMatch = [regex]::Match($joined, 'Video:.*?\s(\d{3,5})x(\d{3,5}).*?,\s*([0-9.]+)\s*fps')
  $audioMatch = [regex]::Match($joined, 'Audio:')
  if (-not $durationMatch.Success -or -not $videoMatch.Success) {
    throw "Unable to parse media metadata from FFmpeg output."
  }
  $duration = ([int]$durationMatch.Groups[1].Value * 3600) +
    ([int]$durationMatch.Groups[2].Value * 60) +
    [double]$durationMatch.Groups[3].Value
  [pscustomobject]@{
    duration = [math]::Round($duration, 3)
    width = [int]$videoMatch.Groups[1].Value
    height = [int]$videoMatch.Groups[2].Value
    fps = [double]$videoMatch.Groups[3].Value
    hasVideo = $true
    hasAudio = $audioMatch.Success
  }
}

$probe = Get-MediaProbe -Path $InputVideo
$blackResult = Invoke-Ffmpeg -Arguments @(
  '-hide_banner', '-i', $InputVideo,
  '-vf', 'blackdetect=d=0.5:pix_th=0.02',
  '-an', '-f', 'null', 'NUL'
)
$blackSegments = @(
  $blackResult.output -split "`r?`n" |
    Where-Object { $_ -match 'black_(start|end|duration)' }
)

$checks = [ordered]@{
  horizontal_1280x720 = ($probe.width -eq 1280 -and $probe.height -eq 720)
  fps_60 = ([math]::Abs($probe.fps - 60) -lt 0.01)
  duration_115_to_125 = ($probe.duration -ge 115 -and $probe.duration -le 125)
  has_video = $probe.hasVideo
  has_audio = $probe.hasAudio
  no_black_segments_over_0_5s = ($blackSegments.Count -eq 0)
}

$report = [ordered]@{
  generatedAt = (Get-Date).ToString('o')
  input = [io.Path]::GetFullPath($InputVideo)
  media = $probe
  checks = $checks
  blackSegments = $blackSegments
  passed = (($checks.Values | Where-Object { -not $_ }).Count -eq 0)
}

$reportDir = Split-Path -Parent $ReportPath
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ReportPath -Encoding UTF8

Write-Output ($report | ConvertTo-Json -Depth 8)
if (-not $report.passed) {
  exit 1
}
