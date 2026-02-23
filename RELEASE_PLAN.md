# Orchestra GitHub 发布整理计划（Draft）

> 目的：先把仓库文档与目录整理到“可对外发布”状态，再进行版本发布。  
> 状态：仅规划，不执行迁移。

## 1. 当前 Markdown 盘点（已扫描）

- 总计：`118` 个 `.md`
- 分布：
  - 根目录：`7`
  - `docs/`：`26`
  - `models/`：`45`
  - `archive/tasks/`：`38`（已归档）
  - 其他：`2`（`reaper_scripts/test/README.md`、`skills/create-song/SKILL.md`）

## 2. 发布目标

1. `README.md` 作为英文主入口（安装 + 快速开始 + 示例 + 能力边界）。
2. 提供 `README_CN.md` 中文入口。
3. 保留技术细节，但将“研究/任务过程文档”从主文档导航移出。
4. 文档结构清晰，外部用户无需阅读 `tasks/` 即可上手。
5. 保持安装路径“便携、最短”。

## 3. 目标目录结构（发布后）

```text
README.md
README_CN.md
ARCHITECTURE.md
docs/
  getting-started/
  api/reaper-mcp/
  reference/
  concepts/
  development/
  roadmap/
  zh/
archive/
  tasks/
research/
  models/
  workflow/
  product/
  background/
  experiments/
.ai/                # 可选：仅维护者相关
```

## 4. 迁移规则（覆盖全部 118 个文件）

## 4.1 根目录文件（逐个）

- `README.md` -> 重写为英文发布版（保留文件名）
- `README_CN.md` -> 新增（由现中文内容重构）
- `ARCHITECTURE.md` -> 改为英文版
- `docs/zh/ARCHITECTURE_CN.md` -> 新增（承接当前中文架构内容）
- `TODO.md` -> `docs/roadmap/TODO.md`
- `TODO_cn.md` -> `docs/roadmap/TODO_CN.md`
- `AGENTS.md` -> `.ai/AGENTS.md`（可选）
- `CLAUDE.md` -> `.ai/CLAUDE.md`（可选）
- `GEMINI.md` -> `.ai/GEMINI.md`（可选）

## 4.2 `docs/` 文件（逐个）

### A) 保留在 docs 主线（仅重组路径）

- `docs/mcp/reaper-mcp/track.md` -> `docs/api/reaper-mcp/track.md`
- `docs/mcp/reaper-mcp/item.md` -> `docs/api/reaper-mcp/item.md`
- `docs/standards/reaper-api-functions.md` -> `docs/reference/reaper-api-functions.md`
- `docs/standards/general_midi_program.md` -> `docs/reference/general-midi-program.md`
- `docs/mcp-configs.md` -> `docs/reference/mcp-configs.md`
- `docs/edit-music.md` -> `docs/concepts/editing-vision.md`

### B) 迁移到 research（从主文档导航移出）

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

## 4.3 `models/` 文档（45 个）

- 规则：`models/**/*.md` 暂不移动目录（避免影响第三方结构）。
- 处理方式：
  - 从主 README/docs 导航中移除。
  - 新增 `models/README.md` 说明：
    - 哪些是上游镜像/实验依赖
    - 哪些是本仓库维护内容
    - 许可证与用途边界

## 4.4 其他文件

- `reaper_scripts/test/README.md` -> `docs/development/reaper-test-guide.md`
- `skills/create-song/SKILL.md`：
  - 若对外公开技能体系 -> `docs/development/skills/create-song.md`
  - 若仅内部维护 -> `.ai/skills/create-song/SKILL.md`

## 5. 文档重写任务（发布必须）

## 5.1 README（英文）

最小结构建议：
1. What is Orchestra
2. Installation
3. Quick Start (5 min)
4. REAPER integration
5. Core capabilities
6. Limitations
7. Docs index
8. Contributing / License

## 5.2 README_CN

与英文结构对齐，避免内容漂移。

## 5.3 Architecture

- `ARCHITECTURE.md`：英文主文档
- `docs/zh/ARCHITECTURE_CN.md`：中文版本

## 6. 发布前清单（Checklist）

- [ ] 所有迁移完成，旧路径建立重定向说明（或更新链接）
- [ ] `README.md` 英文可独立指导安装与运行
- [ ] `README_CN.md` 完成并与英文一致
- [ ] docs 索引页可导航到 API、快速开始、开发文档
- [ ] `research/` 与产品文档隔离
- [ ] 检查敏感信息/本地路径/个人内容
- [ ] 更新版本号与 CHANGELOG

## 7. 本次规划中的待确认项

1. `.ai/` 是否公开（`AGENTS.md`、`CLAUDE.md`、`GEMINI.md`、`skills/*`）？
2. `models/` 是否完整保留在公开仓库，还是拆分为子模块/独立仓库？
3. 发布版本号目标：`v0.3.x` 还是 `v0.4.0`？

---

如果你认可这版计划，我下一步可以基于此文档生成：
- 一份 `git mv` 执行清单（不动内容，只迁移路径）
- 一份 README/README_CN 骨架模板
- 一份 docs 索引页模板（`docs/README.md`）
