# 数字人讲解节奏规则

更新：2026-08-08

这份规则用来固定本项目以后自动产出中文讲解类视频的节奏。核心结论只有一句：**数字人说话节奏以讲解干声为准，不以 BGM、画面总时长或 HyperFrames composition 时长为准。**

## 2026-08-08 最终打磨结论

本轮最终采用的交付链路是：

1. 用 Ditto 从讲解干声生成连续数字人，不再用音量挑帧拼接。
2. 用 `sync-ditto-duration.ps1` 把 Ditto 输出锁到讲解干声，当前漂移约 `0.011875s`。
3. 用 `avatar-head-polished.mp4` 作为右下角小头像源：`168x196`、`60fps`、无 B 帧、关键帧间隔 `15`，并做 `0.04s` 感知提前。
4. HyperFrames 页面仍只读取 `assets/avatar-head.mp4`，不改变原来的右下角圆形头像壳子。
5. 底部字幕不再做场景末尾淡出，`.zw` / `.zw.active` / `.zw.past` 全部锁为黑色，避免后半段变灰。
6. 复用脚本：`scripts\render-v13-polished-delivery.ps1`。

完整工作流见：`docs\AUTOMATED-DIGITAL-HUMAN-VIDEO-WORKFLOW.md`。

## 这次问题的根因

当前项目里出现过两类结果：

- 自然度好的 Ditto 输出：头部、眨眼、表情更自然，但视频时长比讲解干声长，实际观感就是数字人说话慢半拍。
- 最后同步较好的短头像输出：嘴型能跟上讲解语音，但它用了更强的逐帧嘴型校正，容易牺牲自然连续性。

真正要固化的是两者的组合：**先让自然 Ditto 输出锁到讲解干声时长，再只做小范围嘴型修正。**

## 时间轴权威顺序

1. `narration.wav` / 讲解干声是唯一说话时钟。
2. Ditto raw 输出只是数字人动作素材，生成后必须用 `ffprobe` 和干声比时长。
3. BGM 和画面总时长可以比干声多 0.4 到 1.0 秒，用来收尾，但不能拿它们去拉伸数字人说话动作。
4. 字幕、卡片、场景节拍应跟随干声或 word timing；视觉尾巴只做闭嘴、停顿、LOGO 或总结。

## 自动化处理规则

每次 Ditto 输出后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\sync-ditto-duration.ps1 `
  -InputVideo project\hyperframes-first180\assets\avatar-ditto-full.mp4 `
  -ReferenceAudio project\hyperframes-first180\assets\narration.wav `
  -OutputVideo project\hyperframes-first180\assets\avatar-ditto-full-synced.mp4 `
  -StatusOutput project\hyperframes-first180\output\verification\avatar-ditto-duration-sync.json
```

脚本会计算：

- `videoDuration`：Ditto raw 视频时长；
- `audioDuration`：讲解干声时长；
- `driftSeconds`：视频比干声多出来或少掉的秒数；
- `speedFactor`：视频应提速或减速的比例；
- `ptsRatio`：写入 FFmpeg `setpts` 的实际比例。

如果 Ditto 视频明显更长，例如 150.84 秒视频对应 126 秒干声，脚本会把视频按 `126 / 150.84` 的 PTS 比例压回干声节奏，并重新封装原始讲解音频。

## 接入点

`scripts/run-ditto-avatar.ps1` 已默认接入时长锁定步骤。正常生产命令仍然是：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run-ditto-avatar.ps1 `
  -AudioPath project\public\narration.wav `
  -SourceImage project\public\generated\presenter-user-avatar-neutral.png `
  -OutputVideo project\public\generated\presenter-ditto.mp4
```

默认流程会额外保留：

- `presenter-ditto-raw.mp4`：Ditto 原始输出，用来追溯；
- `presenter-ditto-duration-sync.json`：时长锁定报告；
- `presenter-ditto.mp4`：已经锁到讲解干声节奏的可用数字人层。

## 验收口径

交付前至少确认四件事：

- 干声、数字人、最终成片的说话段落时长一致，误差不超过 80ms。
- 如果画面总时长长于干声，数字人尾段必须闭嘴或淡出，不能继续假装说话。
- 抽查开头、中段、结尾三个说话点，嘴型开合不能整体慢于音频。
- `duration-sync.json` 必须记录同步比例；如果比例超过 `1.08x`，最终总结里要明说这次对 Ditto raw 做了节奏校准。
