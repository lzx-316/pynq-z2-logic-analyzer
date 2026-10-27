# AI 协作记录

按《PYNQ-Z2逻辑分析仪三周三人分工与提交计划》第十九节要求记录。
每条包含：时间、任务、原始提示词、AI 输出摘要、人工判断、错误和修正、验证方式、复用价值。
禁止把 AI 输出直接当作已验证结果，必须附仿真或上板证据。

---

## 2026-10-13 条目01：Vivado 重建脚本路径修复

| 项目 | 内容 |
|---|---|
| 时间 | 2026-10-13 下午至晚间 |
| 任务 | 把 Vivado 导出的工程重建脚本从"依赖绝对路径"改成"可换目录重建" |
| 原始提示词 | "按文档中所述内容，将我（队长）所需要完成的所有任务详细展开说一下" → 后续"修改 Tcl 路径并准备干净重建" |
| AI 输出摘要 | 生成 `scripts/recreate_project.tcl`（6 处绝对路径改为相对路径）与 `scripts/build_clean_project.tcl`（重建工程 + 综合 + 实现 + 出 bit + 导 XSA + 导时序/资源/DRC 报告） |
| 人工判断 | 采纳路径改写、前置文件存在性检查；未采纳"BD 被锁定时从原工程 .gen 目录导入 wrapper"的写法，改为统一 `make_wrapper` |
| 错误和修正 | 首次改写把 Testbench 映射到 `../rtl/`，实际仓库为 `repo/tb`，报 `Could not find remote file .../rtl/logic_analyzer_tb.v`；由 `validate_required=1` 在 `create_project` 之前拦截，改为 `../tb/logic_analyzer_tb.v`，并增加"所有被引用文件是否存在"的校验（6 个文件全部命中） |
| 验证方式 | Vivado 2026.1 Tcl Console 重建成功（`Tcl file recreate_project.tcl is valid. All files required for project creation is accesable.`）；完整构建 WNS=10.552 ns、约束全部满足、0 Error；新旧 bit 逐字节比对仅 5 字节不同且全部位于文件头日期时间字段 |
| 复用价值 | 可固化为"Vivado 导出脚本路径修复 + 前置校验"的 Skill |

---

## 2026-10-13 条目02：控制寄存器写入加上显式掩码（人工改动，非 AI 建议）

| 项目 | 内容 |
|---|---|
| 时间 | 2026-10-13 |
| 任务 | Notebook 中 AXI GPIO 控制寄存器写入方式 |
| 原始提示词 | 无（队员手工修改） |
| AI 输出摘要 | 无 |
| 人工判断 | 由队长在 6 处 `gpio_ctrl.write()` 后显式加上 `0xffffffff` 写掩码。原写法默认即为整字写入，两者语义等价，不改变功能 |
| 错误和修正 | 无功能问题；副作用是 `repo/pynq` 与 `repo/notebooks` 两份同名 Notebook 出现内容分歧，已通过"只保留 `repo/notebooks` 一份"解决 |
| 验证方式 | 板卡实测 4 通道采集成功、连续 10 次无超时（2026-10-13 证据 `TBD-002`、`TBD-005`） |
| 复用价值 | 写入 GPIO 控制字时显式写出写掩码，便于阅读和评审；同一工程的文件只保留一份，避免版本分歧 |
## 2026-10-24 条目03：报告正文、图表与演示材料

| 项目 | 内容 |
|---|---|
| 时间 | 2026-10-19 至 2026-10-24 |
| 任务 | 把初稿提纲扩写成报告正文，补系统框图与状态迁移图，生成 PPT 与视频脚本 |
| 原始提示词 | "报告呢" → "写吧现在" → "第 2 章的图 2-1、第 3 章的图 3-1 咋补" → "现在就把所有东西做完" |
| AI 输出摘要 | 生成 `docs/report.md`（8 章 + 3 附录，约 5000 字）；用 System.Drawing 生成 `figs/fig2_1_architecture.png` 与 `figs/fig3_1_fsm.png`；生成 `PYNQ-Z2_Logic_Analyzer_v1.pptx`（12 页）与 `video_script.md` |
| 人工判断 | 数据全部取自仓库中的 RTL、时序/资源/DRC 报告与 team 测试记录；队长的四条复审意见（TB 时钟 #10、DRC 统计、章号、日期与 TBD-004）逐条采纳并修正 |
| 错误和修正 | ① 初稿误写 TB 为 100 MHz/2 MSa/s，改为 #10/50 MHz/1 MSa/s；② DRC 由"无未处理违规"细化为 0 Error + 20 条 REQP-1839 + 1 条 CHECK-3；③ 结论引用的章号由第八章改为第六章；④ 日期改为 2026-10-22 并补 TBD-004 |
| 验证方式 | `docs/report.md` 合并进 main（PR #13）；报告中的图与证据路径在 GitHub 渲染正常；PPT 用 python-pptx 回读校验 12 页结构 |
| 复用价值 | 可固化为"从仓库 RTL/报告生成技术报告与演示材料"的 Skill，见 `skills/pynq-logic-analyzer/SKILL.md` |

---
