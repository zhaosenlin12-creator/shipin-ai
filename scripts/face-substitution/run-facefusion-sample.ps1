$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$facefusionRoot = Join-Path $root 'tools\facefusion'
$python = Join-Path $facefusionRoot '.venv-cuda-py310\Scripts\python.exe'
$ffmpeg = Join-Path $facefusionRoot 'bin\ffmpeg.exe'
$sitePackages = Join-Path $facefusionRoot '.venv-cuda-py310\Lib\site-packages'
$config = Get-Content (Join-Path $root 'config\face-substitution.json') -Raw | ConvertFrom-Json
$outputRoot = Join-Path $root 'output\source-style-face-substitution\facefusion'
$swappedVideo = Join-Path $outputRoot 'swapped-sample-15s.mp4'
$finalVideo = Join-Path $outputRoot 'face-substitution-sample-15s.mp4'

New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
if (-not (Test-Path $python)) { throw "FaceFusion Python environment not found: $python" }
if (-not (Test-Path $ffmpeg)) { throw "Local FFmpeg not found: $ffmpeg" }
if (-not (Test-Path $sitePackages)) { throw "FaceFusion site-packages not found: $sitePackages" }

$identityImage = Join-Path $root 'output\source-style-face-substitution\identity\identity-primary.jpg'
$sampleVideo = Join-Path $root 'output\source-style-face-substitution\source\source-sample-15s.mp4'

$oldPath = $env:PATH
$cudaDllPaths = @(
	Join-Path $sitePackages 'nvidia\cublas\bin'
	Join-Path $sitePackages 'nvidia\cuda_runtime\bin'
	Join-Path $sitePackages 'nvidia\cudnn\bin'
	Join-Path $sitePackages 'nvidia\cufft\bin'
	Join-Path $sitePackages 'nvidia\nvjitlink\bin'
)
foreach ($cudaDllPath in $cudaDllPaths) {
	if (-not (Test-Path $cudaDllPath)) { throw "CUDA runtime directory not found: $cudaDllPath" }
}
$env:PATH = (($cudaDllPaths -join ';') + ";$(Split-Path $ffmpeg);$oldPath")
Push-Location $facefusionRoot
try {
	$providerCheck = & $python -c "import onnxruntime as ort; s=ort.get_available_providers(); raise SystemExit(0 if 'CUDAExecutionProvider' in s else 1)"
	if ($LASTEXITCODE -ne 0) { throw 'CUDAExecutionProvider is unavailable in the FaceFusion environment' }
	$facefusionArgs = @(
		'facefusion.py', 'headless-run',
		'--source-paths', $identityImage,
		'--target-path', $sampleVideo,
		'--output-path', $swappedVideo,
		'--processors', 'face_swapper',
		'--face-swapper-model', 'hyperswap_1a_256',
		'--face-swapper-pixel-boost', '512x512',
		'--face-selector-mode', 'reference',
		'--reference-frame-number', '0',
		'--reference-face-distance', '0.3',
		'--execution-providers', 'cuda',
		'--execution-device-id', '0',
		'--execution-queue-count', '1',
		'--video-memory-strategy', 'strict',
		'--output-video-resolution', '1280x720',
		'--output-video-fps', '60',
		'--output-video-quality', '95',
		'--download-providers', 'github', 'huggingface',
		'--log-level', 'info'
	)
	& $python @facefusionArgs
	if ($LASTEXITCODE -ne 0) { throw "FaceFusion failed with exit code $LASTEXITCODE" }

	& $ffmpeg -y -hide_banner -loglevel error -i $swappedVideo -i $sampleVideo -map 0:v:0 -map 1:a:0 -c:v copy -c:a copy -movflags +faststart $finalVideo
	if ($LASTEXITCODE -ne 0) { throw "Audio mux failed with exit code $LASTEXITCODE" }
}
finally {
	Pop-Location
	$env:PATH = $oldPath
}

Write-Output $finalVideo
