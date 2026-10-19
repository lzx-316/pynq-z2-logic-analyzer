# 独立 Tcl 干净重建报告（队友A）

- 日期：2026-10-19
- 负责人：队友A
- 目的：按队长 10-19 要求，使用**自己的环境 + 全新构建目录**独立执行一次 Tcl 干净重建（不依赖队长构建结果）
- 源码版本：main 5d6d324（RTL/约束/测试台经 origin/main 读取）
- 工具：Vivado v2026.1 (win64) Build 6511674（Tue Jun 16 11:02:23 MDT 2026）
- 主机：DYH（队长 10-19 构建报告的主机为 LAPTOP-VRM1P5HO，**环境独立**）
- 构建目录：D:/FPGA/rebuild_a_20261019/build（运行前不存在，全新）
- 构建主机时间：2026-10-19 18:17:23 → 18:19:39（约 2 分 16 秒）

## 1. 使用的脚本（仓库未修改）

- 仓库构建脚本：scripts/build_clean_project.tcl @ main 5d6d324
- 本地临时副本：uild_a.tcl，**仅改两个路径变量**：
  - uild_dir：D:/FPGA/build_clean → D:/FPGA/rebuild_a_20261019/build
  - epo_scripts：D:/FPGA/production/repo/scripts → D:/FPGA/production/pynq-z2-logic-analyzer/scripts
- 本地 wrapper：un_build.tcl，仅做两件事：
  - set_param board.repoPaths [list "D:/FPGA/rebuild_a_20261019/board_repo"]
  - source build_a.tcl
- 说明：本机未安装 	ul.com.tw:pynq-z2:part0:1.0 board file。为**不改仓库脚本**，从官方
  Xilinx/XilinxBoardStore（oards/TUL/pynq-z2/A.0/，file_version 1.0）下载 board files 到本地
  oard_repo/，仅通过 wrapper 注册给本次构建。BD 全部为显式 Tcl，PCW_IMPORT_BOARD_PRESET=None，
  board file 不参与 PS 配置。
- 仓库工作区：**未改动、未提交**（git status 干净，main 未动）。

## 2. 执行命令

`
vivado -mode batch -source D:/FPGA/rebuild_a_20261019/run_build.tcl \
       -log D:/FPGA/rebuild_a_20261019/vivado_build2.log \
       -journal D:/FPGA/rebuild_a_20261019/vivado_build2.jou
`

构建脚本内部：创建工程 → launch_runs synth_1 → launch_runs impl_1 -to_step write_bitstream →
生成 reports → write_hw_platform（XSA）→ 复制 bit/hwh 到 elease_files/。

## 3. 输出文件与路径

| 文件 | 路径 | 大小 |
|---|---|---|
| bit（原始） | uild/logic_analyzer_50m_complete_v2/logic_analyzer_50m_complete_v2.runs/impl_1/design_1_wrapper.bit | 4045771 B |
| hwh（原始） | uild/logic_analyzer_50m_complete_v2/logic_analyzer_50m_complete_v2.gen/sources_1/bd/design_1/hw_handoff/design_1.hwh | 244705 B |
| bit（发布副本） | uild/release_files/logic_analyzer.bit | 4045771 B |
| hwh（发布副本） | uild/release_files/logic_analyzer.hwh | 244705 B |
| XSA | uild/release_files/design_1.xsa | 1640586 B |
| 时序报告 | uild/release_files/timing_summary.rpt | 34035 B |
| 资源报告 | uild/release_files/utilization.rpt | 11934 B |
| DRC 报告 | uild/release_files/drc.rpt | 25839 B |
| 构建日志 | ivado_build2.log / console2.log | — |

SHA256（发布副本）：

`
logic_analyzer.bit   014bcce0d877a8acf852dd03f10a7bced6b172a1225a75000fa0548afa8a0e07
logic_analyzer.hwh   c9619ba683e880ca83e9d6296728a756b2fc8378575908af265e4a9144a2a089
design_1.xsa         1da14822e9ad7d1d705968ca3d10bee9029e58dd85b2d5e58ffb80dcd803ef5b
`

## 4. 时序结果

- 约束：**All user specified timing constraints are met**
- 时钟：clk_fpga_0，周期 20.000 ns（**50 MHz**）
- **WNS = 10.552 ns**；TNS = 0.000 ns；TNS 失败端点 0 / 6204
- WHS = 0.038 ns；THS = 0.000 ns；THS 失败端点 0 / 6204
- WPWS = 9.020 ns；TPWS = 0.000 ns；TPWS 失败端点 0 / 2796

## 5. 资源结果

| 资源 | 使用 | 可用 | 占比 |
|---|---|---|---|
| Slice LUTs | **1891** | 53200 | **3.55%** |
| Slice Registers | **2648** | 106400 | **2.49%** |
| Block RAM Tile | **2** | 140 | **1.43%** |
| DSPs | 0 | 220 | 0.00% |
| Bonded IOB | 4 | 125 | 3.20% |
| BUFGCTRL | 1 | 32 | 3.13% |

## 6. DRC 结果

- 无 Error
- REQP-1839 Warning（RAMB36 async control check）：20 条
- CHECK-3 Warning（Report rule limit reached）：1 条（报告规则上限提示）
- 与队长 10-19 报告完全一致

## 7. 与队长 10-19 干净重建的对比

| 项目 | 队长版（LAPTOP-VRM1P5HO） | 本次独立版（DYH） | 结论 |
|---|---|---|---|
| Vivado | 2026.1 Build 6511674 | 2026.1 Build 6511674 | 一致 |
| WNS / TNS / 失败端点 | 10.552 / 0 / 0 | 10.552 / 0 / 0 | **一致** |
| LUT / FF / BRAM / DSP | 1891 / 2648 / 2 / 0 | 1891 / 2648 / 2 / 0 | **一致** |
| DRC | 0 Error；20×REQP-1839 + CHECK-3 | 同左 | **一致** |
| hwh 内容 | — | 除 TIMESTAMP 行外**逐行相同** | **可复现** |
| 报告 diff | — | 仅 Host 行不同（DYH vs LAPTOP-VRM1P5HO） | 预期 |
| bit 大小 | 4045771 B | 4045771 B | 一致 |
| bit SHA256 | （队长版不同） | 014bcce0… | 不同属正常（bit 内含构建时间戳/布局信息） |

## 8. 结论

- 独立环境 + 全新目录 + Tcl 重建**成功**，综合、实现、bitstream、XSA、报告全部生成。
- 时序、资源、DRC 与队长 10-19 干净重建**完全一致**；hwh 除时间戳外逐行相同。
- 仓库未修改、main 未提交；所有产物均在 D:/FPGA/rebuild_a_20261019/。