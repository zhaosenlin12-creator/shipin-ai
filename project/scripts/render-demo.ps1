param(
  [switch]$SkipPrepare,
  [switch]$SkipNarration
)

$ErrorActionPreference = 'Stop'
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Push-Location $projectRoot
try {
  if (-not $SkipPrepare) { & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'prepare-avatar.ps1') }
  if (-not $SkipNarration) { & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'generate-narration.ps1') }
  npm.cmd run render
  if ($LASTEXITCODE -ne 0) { throw 'Remotion render failed' }
} finally {
  Pop-Location
}
