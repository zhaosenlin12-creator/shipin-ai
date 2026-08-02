$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ffmpeg = Join-Path $root 'tools\facefusion\bin\ffmpeg.exe'
$sourceEarly = Join-Path $root 'project\hyperframes-first120\assets\avatar-0-60.mp4'
$sourceLate = Join-Path $root 'project\hyperframes-first120\assets\avatar-92-120.mp4'
$generated = Join-Path $root 'project\public\generated'
$assets = Join-Path $root 'project\hyperframes-first120\assets'
$work = Join-Path $root 'project\output\avatar-gesture-composites'

if (-not (Test-Path $ffmpeg)) { throw "FFmpeg not found: $ffmpeg" }
New-Item -ItemType Directory -Force $work,$assets | Out-Null

function New-CompositeSegment {
  param(
    [hashtable]$Segment,
    [string]$SourceVideo
  )

  $output = Join-Path $work ("$($Segment.Name).mp4")
  $base = Join-Path $generated $Segment.Base
  if (-not (Test-Path $base)) { throw "Presenter plate not found: $base" }

  $alpha = "255*min(1,min(min(X/18,(W-1-X)/18),min(Y/18,(H-1-Y)/18)))"
  $filter = "[0:v]scale=1280:720:flags=lanczos,setsar=1[base];[1:v]crop=$($Segment.CropW):$($Segment.CropH):$($Segment.CropX):$($Segment.CropY),scale=$($Segment.HeadW):$($Segment.HeadH):flags=lanczos,format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='$alpha'[head];[base][head]overlay=$($Segment.OverlayX):$($Segment.OverlayY):shortest=1,format=yuv420p[out]"

  & $ffmpeg -hide_banner -loglevel error -y `
    -loop 1 -t $Segment.Duration -i $base `
    -ss $Segment.SourceStart -t $Segment.Duration -i $SourceVideo `
    -filter_complex $filter -map '[out]' -t $Segment.Duration -r 30 -an `
    -c:v libx264 -preset medium -crf 17 -movflags +faststart $output
  if ($LASTEXITCODE -ne 0) { throw "Segment build failed: $($Segment.Name)" }

  return $output
}

function Join-CompositeSegments {
  param(
    [string[]]$Inputs,
    [string]$Output
  )

  $args = @('-hide_banner','-loglevel','error','-y')
  foreach ($input in $Inputs) { $args += @('-i',$input) }
  $chains = for ($index = 0; $index -lt $Inputs.Count; $index += 1) { "[$($index):v]" }
  $filter = ($chains -join '') + "concat=n=$($Inputs.Count):v=1:a=0,format=yuv420p[out]"
  $args += @('-filter_complex',$filter,'-map','[out]','-r','30','-c:v','libx264','-preset','medium','-crf','17','-movflags','+faststart',$Output)
  & $ffmpeg @args
  if ($LASTEXITCODE -ne 0) { throw "Segment concat failed: $Output" }
}

$earlySegments = @(
  @{ Name='early-00-explain'; Base='presenter-user-avatar-gesture-explain.png'; Duration=4; SourceStart=0; CropX=400; CropY=75; CropW=280; CropH=270; HeadW=276; HeadH=266; OverlayX=344; OverlayY=76 },
  @{ Name='early-04-point'; Base='presenter-user-avatar-gesture-point.png'; Duration=4; SourceStart=4; CropX=400; CropY=75; CropW=280; CropH=270; HeadW=271; HeadH=261; OverlayX=261; OverlayY=90 },
  @{ Name='early-08-openpalm'; Base='presenter-user-avatar-gesture-openpalm.png'; Duration=4; SourceStart=8; CropX=400; CropY=75; CropW=280; CropH=270; HeadW=268; HeadH=259; OverlayX=345; OverlayY=85 },
  @{ Name='early-12-explain'; Base='presenter-user-avatar-gesture-explain.png'; Duration=4; SourceStart=12; CropX=400; CropY=75; CropW=280; CropH=270; HeadW=276; HeadH=266; OverlayX=344; OverlayY=76 },
  @{ Name='early-16-point'; Base='presenter-user-avatar-gesture-point.png'; Duration=4; SourceStart=16; CropX=400; CropY=75; CropW=280; CropH=270; HeadW=271; HeadH=261; OverlayX=261; OverlayY=90 },
  @{ Name='early-20-openpalm'; Base='presenter-user-avatar-gesture-openpalm.png'; Duration=4; SourceStart=20; CropX=400; CropY=75; CropW=280; CropH=270; HeadW=268; HeadH=259; OverlayX=345; OverlayY=85 },
  @{ Name='early-24-explain'; Base='presenter-user-avatar-gesture-explain.png'; Duration=4; SourceStart=24; CropX=400; CropY=75; CropW=280; CropH=270; HeadW=276; HeadH=266; OverlayX=344; OverlayY=76 },
  @{ Name='early-28-point'; Base='presenter-user-avatar-gesture-point.png'; Duration=4; SourceStart=28; CropX=400; CropY=75; CropW=280; CropH=270; HeadW=271; HeadH=261; OverlayX=261; OverlayY=90 },
  @{ Name='early-32-openpalm'; Base='presenter-user-avatar-gesture-openpalm.png'; Duration=4; SourceStart=32; CropX=400; CropY=75; CropW=280; CropH=270; HeadW=268; HeadH=259; OverlayX=345; OverlayY=85 },
  @{ Name='early-36-point'; Base='presenter-user-avatar-gesture-point.png'; Duration=4; SourceStart=36; CropX=400; CropY=75; CropW=280; CropH=270; HeadW=271; HeadH=261; OverlayX=261; OverlayY=90 }
)

$lateSegments = @(
  @{ Name='late-92-point'; Base='presenter-user-avatar-gesture-point.png'; Duration=4; SourceStart=0; CropX=430; CropY=85; CropW=280; CropH=270; HeadW=297; HeadH=286; OverlayX=257; OverlayY=86 },
  @{ Name='late-96-explain'; Base='presenter-user-avatar-gesture-explain.png'; Duration=4; SourceStart=4; CropX=430; CropY=85; CropW=280; CropH=270; HeadW=303; HeadH=292; OverlayX=341; OverlayY=72 },
  @{ Name='late-100-openpalm'; Base='presenter-user-avatar-gesture-openpalm.png'; Duration=4; SourceStart=8; CropX=430; CropY=85; CropW=280; CropH=270; HeadW=294; HeadH=284; OverlayX=342; OverlayY=81 },
  @{ Name='late-104-point'; Base='presenter-user-avatar-gesture-point.png'; Duration=4; SourceStart=12; CropX=430; CropY=85; CropW=280; CropH=270; HeadW=297; HeadH=286; OverlayX=257; OverlayY=86 },
  @{ Name='late-108-explain'; Base='presenter-user-avatar-gesture-explain.png'; Duration=4; SourceStart=16; CropX=430; CropY=85; CropW=280; CropH=270; HeadW=303; HeadH=292; OverlayX=341; OverlayY=72 },
  @{ Name='late-112-openpalm'; Base='presenter-user-avatar-gesture-openpalm.png'; Duration=4; SourceStart=20; CropX=430; CropY=85; CropW=280; CropH=270; HeadW=294; HeadH=284; OverlayX=342; OverlayY=81 },
  @{ Name='late-116-neutral'; Base='presenter-user-avatar-neutral.png'; Duration=4; SourceStart=24; CropX=430; CropY=85; CropW=280; CropH=270; HeadW=280; HeadH=270; OverlayX=400; OverlayY=85 }
)

$earlyInputs = foreach ($segment in $earlySegments) { New-CompositeSegment -Segment $segment -SourceVideo $sourceEarly }
$lateInputs = foreach ($segment in $lateSegments) { New-CompositeSegment -Segment $segment -SourceVideo $sourceLate }

Join-CompositeSegments -Inputs $earlyInputs -Output (Join-Path $assets 'avatar-gesture-0-40.mp4')
Join-CompositeSegments -Inputs $lateInputs -Output (Join-Path $assets 'avatar-gesture-92-120.mp4')

Get-Item (Join-Path $assets 'avatar-gesture-0-40.mp4'),(Join-Path $assets 'avatar-gesture-92-120.mp4') | Select-Object FullName,Length,LastWriteTime | ConvertTo-Json
