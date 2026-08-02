param(
  [Parameter(Mandatory = $true)][string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$output = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $output | Out-Null

$dittoSource = Join-Path $root 'vendor\ditto-talkinghead'
if (-not (Test-Path $dittoSource)) { $dittoSource = Join-Path $root 'tools\ditto-talkinghead' }
Copy-Item -LiteralPath $dittoSource -Destination (Join-Path $output 'ditto-talkinghead') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $root 'scripts\run-ditto-avatar.ps1') -Destination (Join-Path $output 'run-ditto-avatar.ps1') -Force
Copy-Item -LiteralPath (Join-Path $root 'project\public\generated\presenter-user-avatar-neutral.png') -Destination (Join-Path $output 'presenter-user-avatar-neutral.png') -Force
Copy-Item -LiteralPath (Join-Path $root 'project\hyperframes-first120\assets\narration-voicebox-aligned-proof-clean-mastered.wav') -Destination (Join-Path $output 'narration-proof.wav') -Force

Get-ChildItem -LiteralPath (Join-Path $output 'ditto-talkinghead') -Recurse -Force |
  Where-Object { $_.FullName -match '\\.git($|\\)|__pycache__' } |
  Remove-Item -Recurse -Force

[pscustomobject]@{
  purpose = '15-second Ditto RTX 4060 smoke test'
  code = (Join-Path $output 'ditto-talkinghead')
  sourceImage = (Join-Path $output 'presenter-user-avatar-neutral.png')
  audio = (Join-Path $output 'narration-proof.wav')
  note = 'Download Ditto checkpoints on the target machine; do not copy the current voicebox or FaceFusion environments.'
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'bundle-manifest.json') -Encoding ascii

Get-ChildItem -LiteralPath $output -Recurse -File | Measure-Object -Property Length -Sum | Select-Object Count,@{Name='Bytes';Expression={$_.Sum}} | ConvertTo-Json
