# PYNQ-Z2可编程逻辑分析仪

## 项目定位

本项目为2026年全国大学生嵌入式芯片与系统设计竞赛FPGA创新设计赛道的参赛作品。当前版本以已经上板验证的 logic_analyzer_50m_complete_v2 为冻结基线。

## 当前功能

- 4通道数字信号采集
- 2048点环形缓存
- 256点预触发和256点后触发
- 上升沿、下降沿和任意边沿触发
- 内部测试模式
- PYNQ Overlay加载
- BRAM数据读取
- 4通道波形显示
- CSV数据导出

## 目录说明

| 目录 | 内容 |
|---|---|
| rtl | 可综合Verilog源码 |
| tb | Testbench |
| constraints | PYNQ-Z2约束 |
| pynq | bit、hwh、xsa和Notebook发布文件 |
| notebooks | 实验和演示Notebook |
| scripts | Vivado Tcl脚本 |
| reports | 时序、资源和DRC报告 |
| docs | 项目文档 |

## 已确认基线结果

- Vivado 2026.1
- 器件：xc7z020clg400-1
- 上板验证：通过
- 时序约束：满足
- WNS：10.552 ns
- LUT：3.55%
- Slice Register：2.49%
- 内部测试模式：通过
- Pmod外部输入：尚未验证

## 重要说明

当前冻结版本不依赖Pmod外部输入。正式演示优先使用内部测试模式；在确保稳定后再考虑Pmod扩展和UART解码。
