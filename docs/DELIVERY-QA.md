# Final Delivery QA

更新：2026-08-09

本文件记录本轮收尾时保留的两个最终成片。中间渲染目录已经清理，验收结果保留在这里。

## 保留成片

| 成片 | 用途 | 规格 |
| --- | --- | --- |
| `cartoon90-skill-v13natural-polished-delivery.mp4` | 当前合格基线视频 | `1920x1080`, `60fps`, `40.656s`, `48000Hz stereo` |
| `douyin-codex-novel-skill-replica.mp4` | Douyin 参考内容复刻成片 | `1920x1080`, `60fps`, `40.656s`, `48000Hz stereo` |

## 数字人同步

两个交付视频使用同一套最终节奏规则：

- 讲解干声是数字人口型时间权威。
- Ditto raw 输出生成后先做时长锁定。
- 小头像层做 `0.04s` 感知提前、`60fps`、无 B 帧、关键帧间隔 `15`。

同步报告关键值：

```json
{
  "videoDuration": 39.88,
  "audioDuration": 39.868125,
  "outputDuration": 39.866667,
  "driftSeconds": 0.011875,
  "speedFactor": 1.000298,
  "ptsRatio": 0.999702,
  "outputFps": 60,
  "synced": true
}
```

合格线：`driftSeconds < 0.08`。

## 清理结果

已删除旧版 `cartoon90-skill-v13*.mp4`、根目录 `_v*` 调试音频/截图/脚本、旧 `hyperframes-first30`、各项目 `output` / `renders` / `snapshots`、临时抽帧和探测目录。

私有或生成资产保留在本机 `local/final-approved-assets`，不进入 Git。
