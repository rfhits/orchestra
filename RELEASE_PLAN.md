# Orchestra GitHub 发布整理计划（Pending）

> 目的：只保留当前未完成的发布整理项。  
> 说明：已完成项已从本文件移除。

## 1) 待迁移文档

### 1.1 `docs/` -> `research/`（从主导航移出）

- `docs/product-direction.md` -> `research/product/product-direction.md`
- `docs/existing-music-ai-products.md` -> `research/product/existing-music-ai-products.md`
- `docs/music-model-abilities.md` -> `research/models/music-model-abilities.md`
- `docs/music-models/models-investigation.md` -> `research/models/models-investigation.md`
- `docs/music-models/music-models.md` -> `research/models/music-models.md`
- `docs/music-models/summary.md` -> `research/models/summary.md`
- `docs/music-models-by-abilities/accompaniment_with_audio_models.md` -> `research/models/by-ability/accompaniment_with_audio_models.md`
- `docs/music-models-by-abilities/accompaniment_with_midi_models.md` -> `research/models/by-ability/accompaniment_with_midi_models.md`
- `docs/music-models-by-abilities/backing_midi_to_audio_models.md` -> `research/models/by-ability/backing_midi_to_audio_models.md`
- `docs/music-models-by-abilities/description_to_midi.md` -> `research/models/by-ability/description_to_midi.md`
- `docs/music-models-by-abilities/lyrics_to_audio_models.md` -> `research/models/by-ability/lyrics_to_audio_models.md`
- `docs/music-models-by-abilities/lyrics_to_midi_models.md` -> `research/models/by-ability/lyrics_to_midi_models.md`
- `docs/music-models-by-abilities/melody_harmonization.md` -> `research/models/by-ability/melody_harmonization.md`
- `docs/music-models-by-abilities/transcribe_from_audio_to_midi.md` -> `research/models/by-ability/transcribe_from_audio_to_midi.md`
- `docs/music-models-by-abilities/unified_models.md` -> `research/models/by-ability/unified_models.md`
- `docs/auto-music-production/audio-analysis-from-mix.md` -> `research/workflow/audio-analysis-from-mix.md`
- `docs/auto-music-production/workflow-generation-deconstruction.md` -> `research/workflow/workflow-generation-deconstruction.md`
- `docs/music-production-background/official-music-production.md` -> `research/background/official-music-production.md`
- `docs/music-production-background/trash-music-production.md` -> `research/background/trash-music-production.md`
- `docs/extend_midi.md` -> `research/experiments/extend_midi.md`

### 1.2 其他

- `reaper_scripts/test/README.md` -> `docs/development/reaper-test-guide.md`

## 2) `models/` 文档策略（待执行）

- 暂不移动 `models/**/*.md`（避免影响第三方结构）。
- 从主 README/docs 导航中移除 `models/` 深链。
- 新增 `models/README.md` 说明：
  - 上游镜像 / 实验依赖
  - 本仓库维护内容
  - 许可证与用途边界

## 3) 发布前清单

- [ ] 所有迁移完成，旧路径链接更新
- [ ] `research/` 与产品文档完成隔离
- [ ] 检查敏感信息/本地路径/个人内容
- [ ] 更新版本号与 CHANGELOG

## 4) 待确认

1. `models/` 最终策略：保留在主仓库 or 拆分子模块/独立仓库？
2. 目标版本号：`v0.3.x` 还是 `v0.4.0`？
