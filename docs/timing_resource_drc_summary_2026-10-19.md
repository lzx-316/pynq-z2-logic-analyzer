# 时序、资源与 DRC 汇总（2026-10-19 干净重建）

- 对应交付项：10 月 22 日前提交的"时序、资源、DRC 摘要"
- 交付状态：**已完成**（本文件即交付物）
- 数据来源 1（主）：队长 2026-10-19 干净重建报告
  - 生成路径：`D:/FPGA/build_clean/release_files/`
  - 对应发布分支：`chore/v0.2-release`（`ed71a1c`，证据提交 `d2bd46a`）
  - 报告文件：`reports/timing_summary.rpt`、`reports/utilization.rpt`、`reports/drc.rpt`
- 数据来源 2（交叉复核）：队友A 2026-10-19 独立 Tcl 干净重建
  - 归档目录：`team/evidence/2026-10-19/independent_rebuild_A/`
  - 构建主机：`DYH`（与队长构建主机 `LAPTOP-VRM1P5HO` 不同，环境独立）
  - 源码版本：main `5d6d324`
- 工具版本：Vivado v.2026.1 (win64) Build 6511674（Tue Jun 16 11:02:23 MDT 2026）
- 设计：`design_1_wrapper`
- 报告时间：2026-10-19 12:27:22 ~ 12:27:26（与 hwh 时间戳 12:23:48 属同一构建会话）

## 0. 一页速览

| 指标 | 结果 |
|---|---|
| 时序 | **全部约束满足**；WNS **10.552 ns**；TNS 0；失败端点 **0 / 6204** |
| 时钟 | `clk_fpga_0` = **50 MHz**（20 ns 周期） |
| 资源 | LUT **1891（3.55%）**、FF **2648（2.49%）**、BRAM **2（1.43%）**、DSP **0** |
| DRC | **0 Error**；20×`REQP-1839` Warning + 1×`CHECK-3` Warning（与基线一致） |
| 复现性 | 两次独立构建（不同主机）数值完全一致；hwh 除 `TIMESTAMP` 外逐行相同 |

## 1. 时序

结论：**所有用户约束满足**（All user specified timing constraints are met）。

| 时钟 | 波形 | 周期 | 频率 |
|---|---|---|---|
| `clk_fpga_0`（PS FCLK_CLK0） | `{0.000 10.000}` | **20.000 ns** | **50.000 MHz** |

| 指标 | 值 |
|---|---|
| WNS（建立） | **10.552 ns** |
| TNS | 0.000 ns |
| TNS 失败端点 / 总端点 | **0 / 6204** |
| WHS（保持） | 0.038 ns |
| THS | 0.000 ns |
| THS 失败端点 / 总端点 | **0 / 6204** |
| WPWS（脉冲宽度） | 9.020 ns |
| TPWS | 0.000 ns |
| TPWS 失败端点 / 总端点 | **0 / 2796** |
| `async_default` 路径组 | WNS 15.148 ns，失败端点 0 / 116 |

## 2. 资源

| 资源 | 使用量 | 可用量 | 占比 |
|---|---|---|---|
| Slice LUTs | **1891** | 53200 | **3.55%** |
| └ LUT as Logic | 1760 | 53200 | 3.31% |
| └ LUT as Memory | 131 | 17400 | 0.75% |
| Slice Registers | **2648** | 106400 | **2.49%** |
| └ Register as Flip Flop | 2648 | 106400 | 2.49% |
| Block RAM Tile | **2** | 140 | **1.43%** |
| └ RAMB36/FIFO | 2 | 140 | 1.43% |
| DSPs | 0 | 220 | 0.00% |
| Bonded IOB | 4 | 125 | 3.20% |
| BUFGCTRL | 1 | 32 | 3.13% |
| MMCM / PLL | 0 / 0 | 4 / 4 | 0.00% |

## 3. DRC

| 规则 | 级别 | 说明 | 数量 |
|---|---|---|---|
| `CHECK-3` | Warning | Report rule limit reached（报告规则上限提示） | 1 |
| `REQP-1839` | Warning | RAMB36 async control check | 20（达到规则报告上限） |

- **无 Error**；全部为 Warning。
- `CHECK-3` 不是设计违规，而是 `report_drc` 的规则报告上限提示（因 `REQP-1839` 达到 20 条上限）。
- 与 2026-10-11 基线报告相比，规则、级别和数量**完全相同**，属既有告警，非本次干净重建引入。

## 4. 与基线的对比

| 指标 | 基线（2026-10-11 报告） | 10-19 干净重建 | 是否一致 |
|---|---|---|---|
| 约束满足 | 是 | 是 | ✅ |
| WNS | 10.552 ns | 10.552 ns | ✅ |
| TNS / 失败端点 | 0 / 0 | 0 / 0 | ✅ |
| Slice LUTs | 1891（3.55%） | 1891（3.55%） | ✅ |
| Slice Registers | 2648（2.49%） | 2648（2.49%） | ✅ |
| Block RAM Tile | 2（1.43%） | 2（1.43%） | ✅ |
| DSPs | 0 | 0 | ✅ |
| DRC（Error / Warning） | 0 / 21（20×REQP-1839 + 1×CHECK-3） | 0 / 21（同左） | ✅ |

两份报告的 diff **仅 `Date` 与 `Command` 两行不同**，其余内容逐行一致。

## 5. 独立重建复核（队友A，2026-10-19）

为验证可复现性，队友A 在自己的环境（主机 `DYH`）用全新构建目录和 Tcl 脚本临时副本独立重建了一次
（仓库脚本未修改、未直接提交 main；完整日志与报告归档于 `team/evidence/2026-10-19/independent_rebuild_A/`）。

| 项目 | 队长版（`LAPTOP-VRM1P5HO`） | 队友A 独立版（`DYH`） | 结论 |
|---|---|---|---|
| Vivado | 2026.1 Build 6511674 | 2026.1 Build 6511674 | 一致 |
| 约束满足 | 是 | 是 | 一致 |
| WNS / TNS / 失败端点 | 10.552 / 0 / 0 | 10.552 / 0 / 0 | **一致** |
| LUT / FF / BRAM / DSP | 1891 / 2648 / 2 / 0 | 1891 / 2648 / 2 / 0 | **一致** |
| DRC（Error / Warning） | 0 / 21 | 0 / 21 | **一致** |
| hwh | — | 除 `TIMESTAMP` 行外**逐行相同** | **可复现** |
| 报告 diff | — | 仅 `Host` 行不同 | 预期 |
| bit 大小 | 4045771 B | 4045771 B | 一致 |

说明：`bit` 的 SHA256 因构建时间戳/布局差异而不同，不作为一致性判据；设计一致性以时序、资源、DRC
及 hwh 内容为准。

## 6. 结论与说明

- 10-19 干净重建**复现了已验证基线**：时序满足且余量充足（50 MHz 下 WNS 10.552 ns），资源占用与基线完全一致。
- 两次独立构建（不同主机、全新目录）结果一致，**可复现性得到验证**。
- DRC 无 Error；唯一实质性告警为既有的 `REQP-1839`（RAMB36 异步控制检查），与基线一致。
- 发布候选 bit/hwh 的板级 smoke test 见 `team/evidence/2026-10-19/TBD-017_result.md`。
- 原始报告：`reports/`（发布分支 10-19 版本）与 `team/evidence/2026-10-19/independent_rebuild_A/`。