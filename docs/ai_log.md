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
