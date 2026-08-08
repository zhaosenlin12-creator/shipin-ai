# AI 讲解类数字人成片工作流

更新：2026-08-08

本文固定本项目当前可复用的视频生产方式：中文讲解音频 + HyperFrames 手绘卡片动画 + 右下角“小C”数字人。目标不是重新设计页面，而是稳定产出“节奏对、数字人自然、字幕清楚、最终能交付”的同类成片。

## 当前交付基线

- 最终成片：`D:\kaifa_stu\shipin-ai\cartoon90-skill-v13natural-polished-delivery.mp4`
- HyperFrames 项目：`D:\kaifa_stu\shipin-ai\project\hyperframes-first180`
- Composition：`project\hyperframes-first180\index.html`
- 讲解干声：`D:\kaifa_stu\shipin-ai\local\final-approved-assets\_v13h_narration.wav`
- 最终混音：`D:\kaifa_stu\shipin-ai\local\final-approved-assets\_v13h_mix.wav`
- 连续数字人源：`project\hyperframes-first180\assets\avatar-ditto-v13h-natural.mp4`
- 精修小头像源：`project\hyperframes-first180\assets\avatar-head-polished.mp4`
- 原工作流头像入口：`project\hyperframes-first180\assets\avatar-head.mp4`

最终规格：

- 分辨率：`1920x1080`
- 帧率：`60fps`
- 时长：`40.656s`
- 音频：`AAC 192k, 48000Hz, stereo`

## 清理后的目录约定

本轮收尾后，根目录只保留最终成片和工程入口。生成过程中的私有音频、BGM、头像源图不进 Git，统一放在：

```powershell
D:\kaifa_stu\shipin-ai\local\final-approved-assets
```

这个目录被 `.gitignore` 排除。换机器复现时，需要先把自己的合法头像源图和可用音频资产放回对应路径；如果只是复刻新选题，优先使用 `scripts\render-douyin-codex-novel.ps1`，它会从脚本文本自动生成讲解音频，再驱动 Ditto。

## Skill / 工具分工

### 1. cartoon-clip-pipeline

负责“中文讲解短视频”的总生产框架：

- 脚本拆成多段 caption / scene。
- 生成或整理中文讲解音频。
- 对音频做裁尾、交叉淡化、峰值归一。
- 生成 Ian / 小黑式手绘卡片视觉。
- 组装 HyperFrames HTML。
- 抽帧验收页面布局、字幕和头像遮挡。

### 2. hyperframes

负责所有视频画面时间线：

- `index.html` 是唯一画面合成入口。
- 场景用 `data-start` / `data-duration` 固定时间。
- 右下角数字人仍然是 `<video src="assets/avatar-head.mp4">`，不改页面结构。
- 底部字幕由 GSAP 时间线逐字推进。
- 画面先渲染成无声视频，再由 FFmpeg 混入最终音频。

### 3. hyperframes-cli

负责检查、预览和渲染：

- 当前项目固定使用 `hyperframes@0.7.87`，避免新版检查器把旧页面里的设计性重叠当成阻塞项。
- 渲染命令固定为 60fps high。
- 输出先落到 `project\hyperframes-first180\output\...noaudio.mp4`。

### 4. Ditto TalkingHead

负责数字人自然连续动作：

- 使用讲解干声直接驱动数字人。
- 不再用“按音量挑帧拼头像”的旧办法。
- Ditto 输出必须先和讲解干声做时长锁定，再裁成右下角头像。

### 5. FFmpeg / FFprobe

负责媒体工程：

- 音频转 16k 给 Ditto。
- 裁切、缩放、降噪、锐化数字人头像。
- 生成 60fps、小尺寸、关键帧密集的头像视频。
- HyperFrames 无声画面和最终混音封装。
- 检查时长、帧率、分辨率、音频采样率。

### 6. PowerShell 脚本

负责把流程固化：

- `scripts\run-ditto-avatar.ps1`：从讲解干声和头像源图生成连续 Ditto 数字人。
- `scripts\sync-ditto-duration.ps1`：把 Ditto raw 输出锁到讲解干声时长。
- `scripts\render-v13-polished-delivery.ps1`：本轮新增，一键完成头像精修、HyperFrames 渲染和最终混音。

## 完整生产步骤

### Step 0：确定视频内容和画面风格

输入：

- 一条中文讲解主题。
- 8 到 15 个场景短句。
- 每段尽量 4 到 7 秒，适合短视频观看。

本项目当前风格：

- 白底纸感。
- 大字标题。
- 彩色描边卡片。
- 手绘箭头。
- 底部字幕条。
- 右下角圆形“小C”数字人。

注意：这类视频不是营销落地页，不要临时改成 126 秒叠层视频，也不要把数字人放成全屏口播。

### Step 1：生成讲解音频

目标：拿到一条节奏自然的讲解干声。

当前文件：

```powershell
D:\kaifa_stu\shipin-ai\local\final-approved-assets\_v13h_narration.wav
```

要求：

- 干声是数字人口型唯一时钟。
- 不能用 BGM 或画面总时长反向拉伸数字人。
- 干声结尾可以比最终画面短一点，但数字人到干声结尾后必须闭嘴或静止。

验收：

```powershell
ffprobe -v error -show_entries format=duration -of json local\final-approved-assets\_v13h_narration.wav
```

### Step 2：生成 BGM 混音

目标：把讲解干声和 BGM 合成最终混音。

当前文件：

```powershell
D:\kaifa_stu\shipin-ai\local\final-approved-assets\_v13h_mix.wav
```

本项目当前混音时长是 `40.656s`。最终成片时长跟这个文件一致。

验收：

```powershell
ffprobe -v error -show_entries format=duration:stream=sample_rate,channels -of json local\final-approved-assets\_v13h_mix.wav
```

### Step 3：生成连续数字人

目标：用讲解干声驱动 Ditto，生成连续自然的人脸视频。

命令模板：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run-ditto-avatar.ps1 `
  -AudioPath local\final-approved-assets\_v13h_narration.wav `
  -SourceImage project\hyperframes-first180\assets\_face_source.png `
  -OutputVideo project\hyperframes-first180\assets\avatar-ditto-v13h-natural.mp4 `
  -PythonPath C:\Users\Administrator\AppData\Local\Programs\Python\Python310\python.exe `
  -OutputFps 60 `
  -SyncStatusOutput project\hyperframes-first180\output\verification\avatar-ditto-v13h-natural-sync.json
```

输出：

- `avatar-ditto-v13h-natural-ditto-raw.mp4`：Ditto 原始结果。
- `avatar-ditto-v13h-natural.mp4`：时长已锁到讲解干声的连续结果。
- `avatar-ditto-v13h-natural-sync.json`：同步报告。

当前同步报告重点：

- 讲解干声：`39.868125s`
- Ditto 输出：`39.866667s`
- 漂移：约 `0.011875s`
- 状态：`synced: true`

验收标准：

- 漂移小于 `80ms`。
- 视频帧率为 `60fps`。
- 不能使用 `_avatar_align_v13aa.py` 那种按音量挑帧拼接的结果作为最终头像。

### Step 4：裁成右下角小头像并精修

目标：把 Ditto 480x720 连续头像裁成原页面右下角 `168x196` 圆形头像源。

本轮精修规则：

- 保留原头像壳子尺寸：`168x196`。
- 裁切：`scale=168:-2,crop=168:196:0:28`。
- 数字人画面相对讲解提前 `0.04s`，用于抵消感知上的口型迟滞。
- 轻微降噪：`hqdn3d=1:1:3:3`。
- 轻微锐化：`unsharp=3:3:0.28`。
- 60fps。
- 无 B 帧：`-bf 0`，方便 HyperFrames 稳定逐帧抽取。
- 关键帧间隔：`15`，减少小头像 seek 抽帧误差。

命令：

```powershell
ffmpeg -hide_banner -y `
  -i project\hyperframes-first180\assets\avatar-ditto-v13h-natural.mp4 `
  -vf "trim=start=0.04,setpts=PTS-STARTPTS,scale=168:-2,crop=168:196:0:28,hqdn3d=1:1:3:3,unsharp=3:3:0.28:3:3:0.0,tpad=stop_mode=clone:stop_duration=0.86,fps=60,format=yuv420p" `
  -an -frames:v 2440 `
  -c:v libx264 -preset slow -crf 15 -bf 0 -g 15 -keyint_min 15 `
  -movflags +faststart `
  project\hyperframes-first180\assets\avatar-head-polished.mp4
```

接入原工作流：

```powershell
Copy-Item -Force project\hyperframes-first180\assets\avatar-head-polished.mp4 project\hyperframes-first180\assets\avatar-head.mp4
Copy-Item -Force project\hyperframes-first180\assets\avatar-head-polished.mp4 project\hyperframes-first180\assets\avatar-head-synced.mp4
```

### Step 5：修正底部字幕颜色

问题：

- 旧脚本在每个场景末尾执行 `tl.to(elZh, { opacity: 0.3 })`。
- 下一场没有恢复 `opacity: 1`，所以后面字幕整体变灰。

当前规则：

- `.zw` 字色固定 `#000000`。
- `.zw.active` 也固定 `#000000`，只保留轻微上浮和加粗。
- 每个新场景开始时 `gsap.set(elZh, { opacity: 1 })`。
- 删除场景末尾字幕淡出。

对应文件：

```powershell
project\hyperframes-first180\index.html
```

### Step 6：HyperFrames 渲染无声画面

目标：保持原页面风格，只让画面和小头像一起出成无声 MP4。

命令：

```powershell
Set-Location D:\kaifa_stu\shipin-ai\project\hyperframes-first180
npx --yes hyperframes@0.7.87 render . `
  --output output\cartoon-v13natural-polished-noaudio.mp4 `
  --fps 60 `
  --quality high
```

预期警告：

- `google_fonts_import`：当前页面仍使用 Google Fonts，渲染器会缓存并注入确定性 font-face。
- `audio_file_without_element`：composition 里没有 `<audio>`，这是预期，因为最终音频由 FFmpeg 混入。

这两个警告不影响最终交付。

### Step 7：混入最终讲解音频

目标：把无声画面和 `local\final-approved-assets\_v13h_mix.wav` 合成最终交付。

命令：

```powershell
Set-Location D:\kaifa_stu\shipin-ai
ffmpeg -hide_banner -y `
  -i project\hyperframes-first180\output\cartoon-v13natural-polished-noaudio.mp4 `
  -i local\final-approved-assets\_v13h_mix.wav `
  -c:v copy `
  -c:a aac -b:a 192k `
  -shortest `
  -movflags +faststart `
  cartoon90-skill-v13natural-polished-delivery.mp4
```

### Step 8：一键复用脚本

本轮已经固化为脚本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\render-v13-polished-delivery.ps1
```

默认会执行：

1. 从 `avatar-ditto-v13h-natural.mp4` 生成 `avatar-head-polished.mp4`。
2. 覆盖 `avatar-head.mp4` 和 `avatar-head-synced.mp4`。
3. 用 `hyperframes@0.7.87` 渲染无声画面。
4. 用 `local\final-approved-assets\_v13h_mix.wav` 混音。
5. 输出 `cartoon90-skill-v13natural-polished-delivery.mp4`。
6. 打印最终 `ffprobe` 规格报告。

可调参数：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\render-v13-polished-delivery.ps1 `
  -AvatarLeadSeconds 0.04 `
  -Fps 60 `
  -TotalFrames 2440 `
  -HyperFramesVersion 0.7.87
```

如果后续觉得口型略早，把 `AvatarLeadSeconds` 调小到 `0.02`；如果仍略慢，可以调到 `0.06`。不要一次改太大。

## 交付验收清单

每次交付前至少跑这些检查。

### 1. 最终规格

```powershell
ffprobe -v error `
  -show_entries format=duration,size,bit_rate:stream=index,codec_type,width,height,r_frame_rate,avg_frame_rate,sample_rate,channels `
  -of json cartoon90-skill-v13natural-polished-delivery.mp4
```

合格：

- `1920x1080`
- `60/1`
- `40.656s` 左右
- audio `48000Hz stereo`

### 2. 抽帧检查

```powershell
New-Item -ItemType Directory -Force project\hyperframes-first180\output\_v13natural_polished_verify | Out-Null
ffmpeg -hide_banner -y -ss 20 -i cartoon90-skill-v13natural-polished-delivery.mp4 -frames:v 1 -update 1 project\hyperframes-first180\output\_v13natural_polished_verify\frame-t20.jpg
```

看三件事：

- 右下角头像还在原圆形壳子里。
- 字幕是黑色，不再整行变灰。
- 头像不挡字幕主体。

### 3. 数字人连续性检查

```powershell
ffmpeg -hide_banner -y `
  -ss 10 -t 1 `
  -i cartoon90-skill-v13natural-polished-delivery.mp4 `
  -vf "crop=210:230:1698:728,fps=12,scale=105:115,tile=12x1" `
  -frames:v 1 `
  project\hyperframes-first180\output\_v13natural_polished_verify\avatar-motion-t10-sheet.jpg
```

合格：

- 12 个小头像里嘴型是连续变化。
- 没有几个固定嘴型来回硬跳。
- 头部没有明显闪跳。

### 4. 同步报告检查

```powershell
Get-Content project\hyperframes-first180\output\verification\avatar-ditto-v13h-natural-sync.json -Encoding UTF8
```

合格：

- `synced: true`
- `driftSeconds < 0.08`
- `outputFps: 60`

## 常见失败和修法

### 数字人一卡一卡

原因：

- 使用了按音量挑帧拼接的头像源。

修法：

- 重新用 Ditto 从讲解干声生成连续头像。
- 只允许 `avatar-ditto-*-natural.mp4` 这类连续结果进入最终裁切。

### 数字人口型慢半拍

原因：

- Ditto raw 输出时长没有锁到讲解干声。
- 或最终小头像没有做感知提前。

修法：

- 先看 `duration-sync.json`。
- 漂移大于 80ms 必须重新跑 `sync-ditto-duration.ps1`。
- 微调 `AvatarLeadSeconds`，建议范围 `0.02` 到 `0.06`。

### 字幕后面变灰

原因：

- `elZh` 被 GSAP 淡出到 `opacity: 0.3`。

修法：

- 删除字幕淡出 tween。
- 每个场景开始时恢复 `opacity: 1`。
- `.zw` / `.zw.active` / `.zw.past` 全部锁黑。

### 最终视频没声音

原因：

- HyperFrames 渲染的是无声画面，这是正常中间产物。
- 还没有执行 FFmpeg 混音步骤。

修法：

- 用 `local\final-approved-assets\_v13h_mix.wav` 执行 Step 7。

### 页面风格跑偏

原因：

- 临时新建了另一个 HTML composition。
- 或把数字人改成覆盖式口播层。

修法：

- 回到 `project\hyperframes-first180\index.html`。
- 只替换 `assets\avatar-head.mp4`。
- 不改变 `.avatar-shell`、`.subtitle-strip`、场景卡片结构。

## 后续生产新视频时的最小改动

同类视频只换这些：

1. 文案和 `SCENES`。
2. 讲解干声。
3. 混音。
4. Ditto 连续数字人源。
5. 卡片文字和场景视觉。

不要换这些：

1. `avatar-head.mp4` 的接入文件名。
2. 右下角头像壳子位置。
3. 先无声渲染再 FFmpeg 混音的交付方式。
4. 以讲解干声为数字人口型时间权威的规则。
