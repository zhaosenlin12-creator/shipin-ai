# Douyin 参考视频复刻示例

本示例复刻用户给出的 Douyin 链接内容：

`https://www.douyin.com/user/self?modal_id=7669822357413981523`

浏览器中识别到的原视频主题是：

> 第7集：用 Codex 写小说，这6个 Skill 你必须知道。

复刻不是照搬原平台画面，而是把原视频章节内容蒸馏进本项目已经调好的交付风格：浅色纸感背景、手绘卡片、底部黑色字幕、右下角自然同步的小C数字人。

## 一键产出

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\render-douyin-codex-novel.ps1
```

默认输出：

```text
D:\kaifa_stu\shipin-ai\douyin-codex-novel-skill-replica.mp4
```

最终验收规格：

- `1920x1080`
- `60fps`
- `40.656s`
- 音频 `48000Hz stereo`
- Ditto 同步漂移 `0.011875s`，状态 `synced: true`

## 新手先看这张分工表

| 文件 / 工具 / Skill | 负责什么 | 新手是否要改 |
| --- | --- | --- |
| `assets\reference-summary.md` | 记录参考视频标题、作者、章节、可见要点 | 换参考视频时要改 |
| `assets\narration-codex-novel.txt` | 最终讲解文案，决定数字人口型和字幕节奏 | 换内容时要改 |
| `project\hyperframes-douyin-codex-novel\index.html` | 画面、卡片、字幕、小C数字人位置 | 换卡片文案时要改 |
| `scripts\render-douyin-codex-novel.ps1` | 一键编排 TTS、音频对齐、Ditto、HyperFrames、FFmpeg 合成 | 默认不用改 |
| `scripts\run-ditto-avatar.ps1` | 调 Ditto 生成连续自然数字人，并自动时长锁定 | 默认不用改 |
| `scripts\sync-ditto-duration.ps1` | 把 Ditto raw 输出压到讲解干声时长 | 默认不用改 |
| `hyperframes` | 把 HTML composition 渲染成无声画面 | 默认不用改 |
| `hyperframes-animation` | 管理 seek-safe 的卡片动画和字幕时间线 | 改动画时才看 |
| `media-use` | 处理 TTS、音频裁剪、混音、字幕素材等媒体问题 | 换声音/BGM 时才看 |
| `FFmpeg / FFprobe` | 裁头像、混音、封装、验收视频规格 | 默认不用改 |

## 从 0 到成片的完整步骤

### Step 1：蒸馏参考视频

打开参考链接，先不要急着照抄画面。只记录四类信息：

1. 标题：这条视频到底讲什么。
2. 作者/账号：方便回溯来源。
3. 章节：每个时间点讲了什么。
4. 结构：开头钩子、主体列表、结尾提醒。

本例蒸馏结果写在：

```text
project\hyperframes-douyin-codex-novel\assets\reference-summary.md
```

### Step 2：写 35 到 40 秒讲解稿

讲解稿不要太长。当前视频的最终画面是 `40.656s`，其中干声控制在 `39.868125s`，最后留一点视觉收尾。

本例讲解稿写在：

```text
project\hyperframes-douyin-codex-novel\assets\narration-codex-novel.txt
```

写稿规则：

- 每句话短一点，方便字幕和口型追上。
- 列表型内容用“第一个、第二个、第三个”推进。
- 结尾必须有一句总结，避免视频突然停。
- 不要把参考视频平台里的 UI 直接搬进来，本项目复刻的是内容和节奏。

### Step 3：生成讲解干声

脚本调用 `edge-tts`：

```powershell
edge-tts --voice zh-CN-YunxiNeural --rate +18% --file assets\narration-codex-novel.txt --write-media output\narration-edge-raw.mp3
```

然后用 FFmpeg 把干声压到固定时长：

```text
39.868125s
```

这一步很重要：后面的数字人口型、字幕推进、画面节拍都以这条干声为准。

### Step 4：生成同步数字人

脚本调用：

```powershell
scripts\run-ditto-avatar.ps1
```

它会做三件事：

1. 把讲解音频转成 Ditto 需要的 `16kHz mono wav`。
2. 用头像源图和讲解干声生成 Ditto raw 视频。
3. 自动调用 `sync-ditto-duration.ps1`，把 raw 视频锁到干声时长。

同步验收看：

```text
project\hyperframes-douyin-codex-novel\output\verification\avatar-ditto-sync.json
```

合格标准：

- `synced: true`
- `driftSeconds < 0.08`
- `outputFps: 60`

本轮结果是 `0.011875s`，已经在可交付范围内。

### Step 5：裁成右下角小C头像

Ditto 输出不是直接放进画面，而是先处理成统一的小头像层：

```text
168x196
60fps
无 B 帧
关键帧间隔 15
0.04s 感知提前
```

这一步解决两个问题：

- 头像动作保持连续，不再一卡一卡。
- 嘴型在观感上更贴近讲解音频，不会慢半拍。

### Step 6：HyperFrames 渲染无声画面

画面入口是：

```text
project\hyperframes-douyin-codex-novel\index.html
```

它负责：

- 纸感背景。
- 8 个手绘信息卡场景。
- 底部黑色逐字字幕。
- 右下角小C数字人。
- 每个 scene 的开始、结束和卡片入场节奏。

渲染命令由脚本自动执行：

```powershell
npx --yes hyperframes@0.7.87 render . --output output\douyin-codex-novel-noaudio.mp4 --fps 60 --quality high
```

### Step 7：FFmpeg 合成最终成片

HyperFrames 只出无声画面，最终音频由 FFmpeg 混入：

```powershell
ffmpeg -i output\douyin-codex-novel-noaudio.mp4 -i output\mix-codex-novel.wav -c:v copy -c:a aac -b:a 192k -shortest douyin-codex-novel-skill-replica.mp4
```

最终文件在仓库根目录：

```text
D:\kaifa_stu\shipin-ai\douyin-codex-novel-skill-replica.mp4
```

### Step 8：交付前验收

先看视频规格：

```powershell
ffprobe -v error -show_entries format=duration,size,bit_rate:stream=index,codec_type,width,height,r_frame_rate,avg_frame_rate,sample_rate,channels -of json douyin-codex-novel-skill-replica.mp4
```

再看三个画面点：

- `2s`：开头标题和小C位置是否正常。
- `18s`：字幕是否仍是黑色，头像是否不挡字幕。
- `34s`：后半段字幕不能变灰，头像口型不能明显落后。

最后看头像连续性：

```powershell
ffmpeg -ss 10 -t 1 -i douyin-codex-novel-skill-replica.mp4 -vf "crop=210:230:1698:728,fps=12,scale=105:115,tile=12x1" -frames:v 1 project\hyperframes-douyin-codex-novel\output\verify\avatar-motion-t10-sheet.jpg
```

如果 12 个头像小格是连续变化的，就说明这次不是旧的“挑帧拼嘴型”方案。

## 工作流拆解

1. `assets\narration-codex-novel.txt`
   写复刻脚本，内容来自 Douyin 页面可见章节要点。

2. `edge-tts`
   生成中文讲解干声，默认声音是 `zh-CN-YunxiNeural`，语速 `+18%`。

3. `ffmpeg`
   把 TTS 干声精确压到 `39.868125s`，再补尾到 `40.656s`，保证画面、字幕、混音和数字人有同一个时间轴。

4. `scripts\run-ditto-avatar.ps1`
   用讲解干声驱动 Ditto 数字人，并调用 `sync-ditto-duration.ps1` 锁定时长。

5. `ffmpeg`
   把 Ditto 输出裁成右下角 `168x196` 小头像，做轻微降噪、锐化、`0.04s` 感知提前、60fps 和密集关键帧。

6. `project\hyperframes-douyin-codex-novel\index.html`
   负责画面、卡片、箭头、逐字字幕和小头像挂载。

7. `hyperframes@0.7.87`
   渲染无声画面。

8. `ffmpeg`
   合成最终带音频 MP4。

## 改成下一个参考视频

只改三处：

1. 改 `assets\reference-summary.md`，记录新参考视频标题、作者、章节和可见要点。
2. 改 `assets\narration-codex-novel.txt`，写成 35 到 40 秒的中文讲解稿。
3. 改 `index.html` 里的 8 个 scene 文案和卡片文字。

然后重新运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\render-douyin-codex-novel.ps1
```

如果数字人略慢，微调：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\render-douyin-codex-novel.ps1 -AvatarLeadSeconds 0.06
```

如果数字人略早，改成：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\render-douyin-codex-novel.ps1 -AvatarLeadSeconds 0.02
```
