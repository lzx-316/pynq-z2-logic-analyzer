# 队友A独立 Tcl 干净重建归档摘要

日期：2026-10-19
负责人：队友A
归档人：队长

## 来源

- 原始资料：`D:\FPGA\data_a\rebuild_a_logs_and_results`
- 原始产物：`D:\FPGA\data_a\rebuild_a_artifacts`
- 源码版本：`main` 的 `5d6d324`
- 独立环境：DYH，使用全新构建目录 `D:/FPGA/rebuild_a_20261019/build`

## 结果

- 独立 Tcl 重建成功，综合、实现、bitstream 和 XSA 均生成
- Vivado：2026.1 Build 6511674
- WNS：10.552 ns
- TNS：0.000 ns，失败端点 0/6204
- WHS：0.038 ns
- LUT：1891（3.55%）
- 寄存器：2648（2.49%）
- BRAM：2（1.43%）
- DSP：0
- DRC：0 Error；20 条 REQP-1839 Warning、1 条 CHECK-3 Warning
- hwh：除 TIMESTAMP 行外与队长 10-19 构建逐行相同
- 报告：与队长版本仅 Host 行不同
- bit：大小一致；SHA256 不同属于构建时间戳和布局差异，不作为失败判据

## 独立构建 SHA256

```text
logic_analyzer.bit  014bcce0d877a8acf852dd03f10a7bced6b172a1225a75000fa0548afa8a0e07
logic_analyzer.hwh  c9619ba683e880ca83e9d6296728a756b2fc8378575908af265e4a9144a2a089
design_1.xsa        1da14822e9ad7d1d705968ca3d10bee9029e58dd85b2d5e58ffb80dcd803ef5b
```

## 归档范围

本目录保存日志、报告、TCL 脚本和 MANIFEST。`rebuild_a_artifacts.zip` 中的 bit/hwh/XSA 保留在本地作为备份，不重复提交到仓库；仓库发布文件以 `pynq/` 中的正式候选版本为准。
