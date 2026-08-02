$ErrorActionPreference = 'Stop'

$ff = (python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())").Trim()
$input = 'C:\kaifa_senlin\shipin-ai\mp4\9e61c373398f12c4179ae3a2ba24060b_raw.mp4'
$output = 'C:\kaifa_senlin\shipin-ai\output\source-style-face-substitution\source'

New-Item -ItemType Directory -Force -Path $output | Out-Null
& $ff -y -hide_banner -loglevel error -ss 30 -i $input -t 15 -map 0:v:0 -map 0:a:0 -c:v libx264 -preset medium -crf 16 -c:a copy "$output\source-sample-15s.mp4"
