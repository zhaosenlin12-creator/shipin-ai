$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$logPath = Join-Path $projectRoot 'output\source-style-render.log'
$errPath = Join-Path $projectRoot 'output\source-style-render.err.log'
$exitPath = Join-Path $projectRoot 'output\source-style-render.exit'
$outputPath = Join-Path $projectRoot 'output\rendered\source-style-first120.mp4'

Remove-Item -LiteralPath $logPath, $errPath, $exitPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $outputPath -Force -ErrorAction SilentlyContinue

$command = "Set-Location -LiteralPath '$projectRoot'; npm.cmd run render *> '$logPath'; [IO.File]::WriteAllText('$exitPath', `$LASTEXITCODE.ToString())"
$process = Start-Process `
  -FilePath 'powershell.exe' `
  -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $command) `
  -WindowStyle Hidden `
  -PassThru

Write-Output ([ordered]@{
  pid = $process.Id
  output = [IO.Path]::GetFullPath($outputPath)
  log = [IO.Path]::GetFullPath($logPath)
  errorLog = [IO.Path]::GetFullPath($errPath)
  exitFile = [IO.Path]::GetFullPath($exitPath)
} | ConvertTo-Json)
