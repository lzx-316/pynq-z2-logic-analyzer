# PYNQ-Z2 四通道逻辑分析仪 v1.0-rc 发布说明

日期：2026-10-27
状态：Release Candidate（发布候选，未最终冻结）
基线提交：`d6e5b08ca151dc4d5b10c3879f76d27cc121a79e`
验证工具：Vivado 2026.1、PYNQ Jupyter、Vivado XSim

## 1. 发布范围

本发布候选保持四通道逻辑分析仪 MVP：

- 4 通道数字采集
- 1 MSa/s 采样率（50 MHz ÷ 50）
- 2048 点环形缓冲
- 预触发 256 点、后触发 256 点
- 上升沿、下降沿、任意边沿触发
- 内部测试模式
- PYNQ Overlay 加载
- Notebook v2 采集、4 通道波形显示与 CSV 导出

Pmod 外部输入不做完整验证；UART 已取消，不纳入本项目最终提交范围。

## 2. 发布产物

发布产物位于 `pynq/`：

| 文件 | 大小 | 校验 |
|---|---:|---|
| `logic_analyzer.bit` | 4,045,771 B | SHA256 `2C1EE29D20F246E7F19C61980F80CF7EB3D16671E88D6464A1D82F190F2EBA20` |
| `logic_analyzer.hwh` | 244,705 B（Git 规范化大小） | Git blob `fabe4fff2dadb9bd4b2c62f5d4d75b5cf84d8a97` |
| `design_1.xsa` | 1,640,581 B | SHA256 `88D46F03D5756F0D7431C46433762AB7012795A6966E4B918EFED62C2A433113` |

`logic_analyzer.bit`、`logic_analyzer.hwh` 和 `design_1.xsa` 来自同一轮 2026-10-19 干净重建。Windows 工作区中的 hwh 可能因 CRLF 换行显示为 249,071 B，Git 规范化内容仍为 244,705 B。

## 3. 验证结果

### 实现结果

- 时钟：`clk_fpga_0`，50 MHz
- WNS：10.552 ns
- TNS：0.000 ns，失败端点 0 / 6204
- WHS：0.038 ns
- WPWS：9.020 ns
- 约束：All user specified timing constraints are met
- LUT：1891（3.55%）
- 寄存器：2648（2.49%）
- Block RAM：2（1.43%）
- DSP：0
- DRC：0 Error；20 条 REQP-1839 Warning + 1 条 CHECK-3 Warning

### 板级与仿真证据

- TBD-010：队友B独立板级复跑通过，CSV 513 行 × 6 列，连续 10 次通过。
- TBD-017：发布候选 bit/hwh 板级 smoke test 通过。
- TBD-004、TBD-011～016：7 个边界用例、42 项断言全部通过。
- TBD-018：队友A在其他主机、全新目录完成独立 Tcl 重建，时序、资源、DRC 与队长版本一致。
- Testbench：TBD-001 两条 PASS 断言通过。

证据目录：

```text
team/evidence/2026-10-19/
team/evidence/tb_log.txt
```

## 4. 软件与文档

- Notebook v2：`notebooks/logic_analyzer_v2.ipynb`
- 设计报告 v1.0：`docs/report.md`
- 报告图：`docs/figs/fig2_1_architecture.png`、`docs/figs/fig3_1_fsm.png`
- 时序、资源、DRC 汇总：`docs/timing_resource_drc_summary_2026-10-19.md`
- 术语表：`docs/glossary.md`
- 复现脚本：`scripts/build_clean_project.tcl`

Notebook v2 已包含 Overlay 检查、7 步状态输出、`write_ctrl()` 兼容处理、CSV 导出和连续 10 次采集。

## 5. 已知限制

1. 采样率固定为 1 MSa/s，暂不支持运行时可配置分频。
2. 缓冲深度固定为 2048 点。
3. 28 位时间戳在 1 MSa/s 下约 268 秒回绕。
4. Pmod 外部输入的电气特性和完整链路未验证，正式演示优先使用内部测试模式。
5. UART 不纳入当前版本。

## 6. 发布前检查

- [x] 发布 bit/hwh/XSA 与同一轮构建配套
- [x] Testbench 与边界测试有日志证据
- [x] TBD-010 板级独立复跑通过
- [x] TBD-017 发布候选 smoke test 通过
- [x] 独立 Tcl 重建结果与队长构建一致
- [x] 报告 v1.0、PPT、图表和时序资源汇总已合入 main
- [ ] 报告 v1.0 最终复核
- [ ] PPT 与视频最终检查（实际 MP4 尚待录制）
- [ ] 团队完整彩排

## 7. 版本冻结说明

本文件描述的是 v1.0-rc 发布候选。最终 `v1.0-rc` 标签应在发布候选 PR 合并、最终报告/PPT/视频检查完成后创建。2026-10-31 功能冻结后只修复 bug，不再增加功能。
