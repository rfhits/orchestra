# 2024-2025 SOTA 主旋律与MIDI提取模型调研报告

**日期**: 2026年1月26日
**目标**: 寻找能提取“干净”旋律（Clean Melody）和高质量 MIDI 的模型，解决现有 Basic Pitch 方案音符破碎、不连贯的问题。

以下是针对不同乐器和场景的 SOTA (State-of-the-Art) 解决方案。

---

## 1. 钢琴转录 (Piano Transcription)

**核心痛点**: Basic Pitch 对钢琴的处理不够连贯，音符容易碎裂。
**推荐方案**: **Transkun**

*   **项目名称**: Transkun
*   **GitHub**: [https://github.com/Yujia-Yan/Transkun](https://github.com/Yujia-Yan/Transkun)
*   **论文支持**: ISMIR 2024 ("Scoring intervals using non-hierarchical transformer for automatic piano transcription")
*   **核心优势**:
    *   声称在钢琴转录任务上达到 SOTA。
    *   使用了 **Semi-CRF (Semi-Markov Conditional Random Fields)** 层来建模音符的持续时间（Duration）。
    *   相比于传统的逐帧分类（Frame-wise Classification），它能直接预测音符事件，从而大大减少碎音符（Fragmented Notes）的产生，生成的 MIDI 更干净、连贯。
*   **安装与复现**:
    ```bash
    pip install transkun
    # 使用
    transkun input_audio.wav output.mid
    ```

---

## 2. 人声/歌声转录 (Singing Voice Transcription)

**核心痛点**: 需要从带伴奏的歌曲或混响严重的人声中提取稳定的主旋律 MIDI。

### 方案 A: ROSVOT (鲁棒性优先)
*   **项目名称**: ROSVOT (Robust Singing Voice Transcription)
*   **GitHub**: [https://github.com/RickyL-2000/ROSVOT](https://github.com/RickyL-2000/ROSVOT)
*   **更新时间**: 2024年11月
*   **核心优势**:
    *   专为**抗噪**设计，能在复杂的伴奏环境下工作。
    *   能够提取音符级（Note-level）的 MIDI，而不仅仅是 F0 曲线。
    *   包含音符与歌词的对齐功能（Note-Word Alignment），对于理解旋律结构非常有帮助。

### 方案 B: SOME (速度优先 / DiffSinger生态)
*   **项目名称**: SOME (Singing-Oriented MIDI Extractor)
*   **GitHub**: [https://github.com/openvpi/SOME](https://github.com/openvpi/SOME)
*   **开发者**: OpenVPI (DiffSinger 的开发团队)
*   **核心优势**:
    *   **极速**: CPU 上 9x 实时速度，GPU 上 300x 实时速度。
    *   专为 AI 歌声合成（SVS）的数据标注设计，准确性很高。
    *   支持微音程（Microtonal）输出，能捕捉人声细腻的转音（如果需要标准 MIDI 可能需要量化）。

---

## 3. 综合与后处理工具 (General & Post-processing)

**核心痛点**: 如何清洗模型输出的“脏” MIDI？

### NeuralNote (学习其后处理逻辑)
*   **项目名称**: NeuralNote
*   **GitHub**: [https://github.com/DamRsn/NeuralNote](https://github.com/DamRsn/NeuralNote)
*   **类型**: VST3/AU 音频插件 (C++)
*   **核心价值**:
    *   它底层其实使用了 Spotify 的 **Basic Pitch**。
    *   但在 Basic Pitch 之上，它实现了一套非常强大的**后处理算法**，用于音符量化（Quantization）、音阶锁定（Scale Snap）和碎片清理。
    *   **复现建议**: 虽然它是 C++ 项目，但可以阅读其源码中的后处理部分，将其逻辑移植到 Python 中，用于优化 Basic Pitch 或其他模型的输出。

### RMVPE (底层 F0 提取备选)
*   **项目名称**: RMVPE (Robust Model for Vocal Pitch Estimation)
*   **GitHub**: [https://github.com/Dream-High/RMVPE](https://github.com/Dream-High/RMVPE) (通常集成在 RVC 项目中)
*   **核心价值**:
    *   目前 RVC (Retrieval-based Voice Conversion) 社区公认最强的 F0 提取器。
    *   如果 ROSVOT/SOME 的效果不理想，可以回退到“手动挡”：使用 RMVPE 提取高精度的 F0 曲线，然后编写自定义算法将其切割成 MIDI 音符。

---

## 4. 建议复现路径 (Action Plan)

1.  **钢琴任务**:
    *   直接安装 `transkun`。
    *   对比测试：`Basic Pitch` vs `Transkun` 处理同一首钢琴曲。
    *   预期：Transkun 的音符应显著更少碎片化。

2.  **人声任务**:
    *   优先尝试 `SOME`（因为安装和运行可能更简单，且速度快）。
    *   如果遇到抗噪问题（背景音乐干扰严重），尝试 `ROSVOT`。

3.  **工程集成**:
    *   在 `mcp_tools/` 中新建 `melody_extraction.py`。
    *   封装上述模型的调用接口，使其可以通过 Gemini 聊天直接调用。
