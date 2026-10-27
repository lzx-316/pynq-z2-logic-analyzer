# 最终回归报告（2026-10-25）

- 阶段：v2.0 冻结后的最终回归
- 被测版本：main `aa5b062`
- 环境：Vivado Simulator 2026.1（Build 6511674）、PYNQ-Z2（xc7z020clg400-1）
- 结论：**仿真与版本链均通过；P0 问题 0 项**。有 1 项 P1 需队长确认（见第 4 节）。

## 0. 交付物一致性速览

| 交付物 | 当前版本 / 指纹 | 对应构建 | 结论 |
|---|---|---|---|
| bit | SHA256 `2c1ee29d20f246e7f19c61980f80cf7eb3d16671e88d6464a1d82f190f2eba20`；4,045,771 B；blob `92e44f0f` | 2026-10-19 干净重建 | ✅ |
| hwh | SHA256 `6340c1c7fd2ecda0da05ee4edfd20f83c69db06c7f270be228b0dbda249ea1f2`；244,705 B；blob `fabe4fff`；`TIMESTAMP=10-19 12:23:48` | 同一次 10-19 构建 | ✅ |
| XSA | SHA256 `88d46f03d5756f0d7431c46433762ab7012795a6966e4b918efed62c2a433113`；1,640,581 B；blob `6cc1d90c` | XSA 内 bit/hwh 与上面两份逐字节一致 | ✅ |
| 报告 | `timing_summary.rpt` / `utilization.rpt` / `drc.rpt`，均为 10-19 12:27:22~26 | 与 hwh 同一构建会话；WNS 10.552、LUT 1891、FF 2648、BRAM 2、DRC 0 Error | ✅ |
| Notebook | `notebooks/logic_analyzer_v2.ipynb`，blob `bcf0062a` | IP 名/地址/深度/pre-post 与 hwh 一致 | ✅ |
| Tcl | `recreate_project.tcl` blob `aae55a9e`；`build_clean_project.tcl` blob `00b8f18` | 自 `5d6d324` 未变；TBD-018 独立重建复现 hwh（除时间戳） | ✅ |
| 设计报告 | `docs/report.md` | 数字与上述报告一致 | ✅ |

## 0.1 最终回归矩阵

| 用例 | 方法 | 结果 | 证据 |
|---|---|---|---|
| TBD-001 | 主 Testbench（xsim） | 两条 PASS（424271 ns / Line 69） | `team/evidence/2026-10-25/final_tb_log.txt` |
| TBD-004、TBD-011~016 | 边界 Testbench（xsim） | 7 用例 42 项断言 ALL PASS | `team/evidence/2026-10-25/final_boundary_log.txt` |
| TBD-010 | 板级（旧 baseline bit） | 通过（Overlay/波形/CSV/连续 10 次） | `team/evidence/2026-10-19/TBD-010_*` |
| TBD-017 | 板级（发布 bit/hwh + v1 Notebook） | 通过（trigger_ptr=257、valid=513、10/10） | `team/evidence/2026-10-19/TBD-017_result.md` |
| TBD-018 | 独立 Tcl 重建（主机 DYH） | 时序/资源/DRC 与队长构建一致 | `team/evidence/2026-10-19/independent_rebuild_A/` |

## 1. 回归测试结果

### 1.1 主 Testbench（TBD-001）

在最新 main 的 RTL 上重跑 `tb/logic_analyzer_tb.v`：

```
PASS: done=1, trigger_ptr=24
PASS: clear returned FSM to IDLE
$finish called at time : 424271 ns : .../tb/logic_analyzer_tb.v Line 69
```

日志：`team/evidence/2026-10-25/final_tb_log.txt`

### 1.2 边界 Testbench（TBD-004、TBD-011~016）

`tb/logic_analyzer_boundary_tb.v` 一次跑完 7 个用例：

```
BOUNDARY_SUMMARY: ALL PASS
```

共 **42 项断言，0 FAIL**（含 pre/post 4 组组合、2100 点环形回绕、采集中 clear）。
日志：`team/evidence/2026-10-25/final_boundary_log.txt`

### 1.3 板级与构建证据（复用已归档结果）

| 证据 | 结论 | 与当前 main 的对应关系 |
|---|---|---|
| TBD-017（发布候选 bit/hwh smoke test） | Overlay 加载成功；done=1、triggered=1、trigger_ptr=257；valid=513；CSV 513×6；连续 10/10 | 使用的就是当前 `pynq/` 的 bit/hwh（blob `92e44f0f` / `fabe4fff`） |
| TBD-010（队友B 独立复跑） | Overlay、波形、CSV、连续 10 次均通过 | 使用的是旧 baseline bit（当时 main 上的 `pynq/`），作为对照 |
| TBD-018（队友A 独立 Tcl 重建） | WNS 10.552、LUT 1891、FF 2648、BRAM 2，与队长构建一致 | 使用的 Tcl/RTL 与当前 main 相同（自 `5d6d324` 未变） |

## 2. 版本一致性检查

### 2.1 bit / hwh / XSA

| 交付物 | 指纹 | 对应关系 |
|---|---|---|
| `pynq/logic_analyzer.bit` | SHA256 `2c1ee29d20f246e7f19c61980f80cf7eb3d16671e88d6464a1d82f190f2eba20`，4045771 B，blob `92e44f0f` | 10-19 干净重建产物 |
| `pynq/logic_analyzer.hwh` | SHA256 `6340c1c7fd2ecda0da05ee4edfd20f83c69db06c7f270be228b0dbda249ea1f2`，244705 B，blob `fabe4fff` | `TIMESTAMP="Mon Oct 19 12:23:48 2026"` |
| `pynq/design_1.xsa` | SHA256 `88d46f03d5756f0d7431c46433762ab7012795a6966e4b918efed62c2a433113`，1640581 B，blob `6cc1d90c` | **XSA 内 `design_1.bit` / `design_1.hwh` 与上面两份逐字节一致** ✅ |

### 2.2 报告

| 报告 | 时间 | 关键结果 |
|---|---|---|
| `reports/timing_summary.rpt` | Mon Oct 19 12:27:23 2026 | 约束全部满足；WNS 10.552 ns；TNS 0；失败端点 0/6204；Design State: Routed |
| `reports/utilization.rpt` | Mon Oct 19 12:27:22 2026 | LUT 1891（3.55%）、FF 2648（2.49%）、BRAM 2（1.43%）、DSP 0 |
| `reports/drc.rpt` | Mon Oct 19 12:27:26 2026 | 0 Error；20×REQP-1839 + 1×CHECK-3 Warning；Design State: Fully Routed |

三份报告的生成路径均为 `D:/FPGA/build_clean/release_files/`，与 hwh 时间戳（12:23:48）属同一构建会话；
比对 2026-10-11 基线报告，数值逐项一致（仅 Date/Command 行不同）。

### 2.3 Notebook

| 文件 | 指纹 | 一致性检查 |
|---|---|---|
| `notebooks/logic_analyzer_v2.ipynb` | blob `bcf0062a` | 使用 `axi_gpio_0` / `axi_gpio_1` / `axi_bram_ctrl_0`，与 hwh 实例名一致；`DEPTH=2048`、`PRE/POST=256`、`ctrl_idle=0x81004000` 与 RTL/hwh 一致 ✅ |
| `notebooks/logic_analyzer_corrected.ipynb` | blob `850c5c66` | 10 处 `gpio_ctrl.write(value, 0xffffffff)`，**已是双参数写法** |

> 注：`docs/report.md` 第六章称"v1 使用单参数写入会报 TypeError"，与当前 main 中 v1 的实际内容不符
> （v1 已全部使用双参数）；v2 的改进是增加了单参数回退的 `write_ctrl()`。这是文档精度问题（P2），不影响运行。

### 2.4 Tcl 与复现

| 文件 | 指纹 | 说明 |
|---|---|---|
| `scripts/recreate_project.tcl` | blob `aae55a9e` | 自 `5d6d324` 未变；独立重建（TBD-018）用它复现出与发布 hwh 除 TIMESTAMP 外逐行相同的结果 ✅ |
| `scripts/build_clean_project.tcl` | blob `00b8f18` | 驱动脚本；`repo_scripts` 仍写死 `D:/FPGA/production/repo/scripts`，在本工作区需改成本地路径（见 P2） |

## 3. 测试记录与报告的一致性

- `docs/report.md`（已合并）中的 WNS/LUT/FF/BRAM/DRC 数字与 `reports/` 一致 ✅
- `docs/timing_resource_drc_summary_2026-10-19.md` 与上述数字一致 ✅
- `team/boundary_test_table_2026-10-19.md` 与 `team/evidence/2026-10-25/final_boundary_log.txt` 一致 ✅

## 4. 问题清单

### P0

**无。**

### P1（需在 10/31 冻结前确认）

1. **发布 bit + Notebook v2 的组合缺少板级证据**
   - TBD-017（发布 bit/hwh smoke test）用的是 `notebooks/logic_analyzer_corrected.ipynb`（v1）；
   - TBD-010（Notebook v2 证据）用的是旧 baseline bit；
   - 两者接口/寄存器映射一致（已验证 IP 名、地址、深度、pre/post），风险低，但严格来说
     "发布 bit + v2" 这个最终演示组合没有上板记录。
   - 建议：队长用发布 bit 跑一次 v2 的 7 步（约 2 分钟）并附截图，或在发布记录中书面确认等价性。

### P2（文档/流程，不阻塞冻结）

1. `scripts/build_clean_project.tcl` 的 `repo_scripts` 路径写死为 `D:/FPGA/production/repo/scripts`，
   在其他目录复现时需改本地路径（TBD-018 已按此方式完成）。
2. `TBD-017_result.md` 未记录板端 `sha256sum logic_analyzer.bit` 的输出；当前 bit 指纹已在本文档中给出，
   建议后续补一行以便追溯。
3. `docs/report.md` 表 5-3 未列出 TBD-001、TBD-006（TBD-001 在 5.1 有文字描述）。
4. `docs/report.md` 关于 v1 单参数写入的表述与仓库实际不符（见 2.3 注）。

## 5. 结论

- 最新 main 上仿真回归全部通过（主 TB 2 条 PASS + 边界 42 项断言）；
- bit/hwh/XSA 三件套逐字节配套，报告与 hwh 属同一 10-19 构建会话，Notebook 与 hwh/寄存器映射一致，
  Tcl 可复现（独立重建已验证）；
- **未发现 P0 问题**。唯一 P1 是"发布 bit + Notebook v2"组合缺板级记录，建议在 10/31 冻结前补一次
  2 分钟 smoke test 或书面确认。

## 6. 10/31 冻结前检查清单

- [x] 最新 main 上主 TB 通过
- [x] 边界测试 7 用例 / 42 项断言通过
- [x] bit/hwh/XSA 逐字节配套
- [x] 报告与 hwh 属同一 10-19 构建会话，数字一致
- [x] Notebook v2 与 hwh 的 IP/地址/深度/pre-post 一致
- [x] Tcl 可复现（TBD-018 独立重建）
- [ ] **P1**：发布 bit + Notebook v2 的交叉板级确认（补测或书面等价说明）
- [ ] 报告 v1.0 最终复核（团队）
- [ ] PPT / 视频最终检查（团队）
- [ ] 完整彩排（团队）

**P0 结论：无 P0 问题。** 唯一 P1 为发布 bit + Notebook v2 的交叉验证，建议 10/31 前完成。

## 7. 证据索引

| 内容 | 位置 |
|---|---|
| 最终主 TB 日志 | `team/evidence/2026-10-25/final_tb_log.txt` |
| 最终边界 TB 日志（42 断言） | `team/evidence/2026-10-25/final_boundary_log.txt` |
| 边界测试表 | `team/boundary_test_table_2026-10-19.md` |
| 时序/资源/DRC 汇总 | `docs/timing_resource_drc_summary_2026-10-19.md` |
| 板级 smoke test | `team/evidence/2026-10-19/TBD-017_result.md` |
| 独立重建归档 | `team/evidence/2026-10-19/independent_rebuild_A/` |
| 设计报告 | `docs/report.md` |