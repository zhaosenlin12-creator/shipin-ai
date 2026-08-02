$ErrorActionPreference = 'Stop'

$ff = (python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())").Trim()
$input = 'C:\JSYSOFT\weixin1\xwechat_files\wxid_irc74agob6ju22_f059\msg\video\2026-08\2d7586ef8d3e30a5654ab0fe981bca6b_raw.mp4'
$output = 'C:\kaifa_senlin\shipin-ai\output\source-style-face-substitution\identity'

New-Item -ItemType Directory -Force -Path $output | Out-Null
& $ff -hide_banner -loglevel error -ss 2 -i $input -frames:v 1 -q:v 2 "$output\identity-primary.jpg"
