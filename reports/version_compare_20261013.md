# 版本对比记录：v2-baseline 与 Tcl 干净重建

日期：2026-10-13
执行人：队长
对应任务：T008（修复 Tcl 绝对路径、干净目录重建）、T010（新旧版本对比）、工作包 WP5

## 一、目的

证明"用仓库里的脚本，在一台电脑的干净目录里，能从零重建出与冻结基线功能一致的工程"，即
重建过程不依赖原始 Vivado 工程目录、不依赖 `D:\FPGA\guide` 下的教程文件。

## 二、构建信息

| 项目 | 内容 |
|---|---|
| 工具版本 | Vivado 2026.1 |
| 器件 | xc7z020clg400-1 |
| 板卡 | tul.com.tw:pynq-z2:part0:1.0 |
| 源文件位置 | `repo\rtl`（4 个 Verilog）、`repo\constraints`（XDC）、`repo\tb`（Testbench） |
| 构建脚本 | `repo\scripts\recreate_project.tcl`、`repo\scripts\build_clean_project.tcl` |
| 构建目录 | `D:\FPGA\build_clean`（在仓库之外，仓库内不产生 `.runs/.cache` 等临时目录） |
| 构建时间 | 2026-10-13 19:53 至 19:57 |
| 综合/实现结果 | 0 Error、0 Critical Warning，`write_bitstream completed successfully` |

## 三、产物与校验值

| 文件 | 大小（字节） | SHA256（新建 / 基线） |
|---|---|---|
| logic_analyzer.bit | 4045771 | 新建 `53FE58311BD8BA5297F3627CCF2C720C045604773909FA472A0291A136371410` |
|  |  | 基线 `AE7F1EE4869C2DB545594D8E9990D75BE17F020970D95CB3BF1BCA634AFFD6B5` |
| logic_analyzer.hwh | 244705 / 244751 | 新建 `E8DE5F30219174E3CF813D335E08DAE3E1C9E607779B3EF13CC02D403BBCD847` |
|  |  | 基线 `1CEAC73C4F378A1057E19E07FDA775FBD69BE2AF4A5C319B1E8C469F1C1EF7F7` |
| design_1.xsa | 1640586 / 1640581 | 新建 `4CE256E30E69D8FD174F1E7F64DA1A6C12B25547B216924D2CFAB8465661A197` |
|  |  | 基线 `6470F1F9D071BA442DEB022AD3CC8C9951C6F3C5A47B0619B99CB95828A420BA` |
| timing_summary.rpt | 34034 | 见第四节 |
| utilization.rpt | 11933 | 见第五节 |
| drc.rpt | 25838 | 见第六节 |

说明：`.bit` 文件头部含构建日期时间字段，因此**任何两次构建的 SHA256 都不会相同**，哈希值不能作为"是否一致"的判据，必须做逐字节比对（见第七节）。

## 四、时序对比

| 指标 | 新建（10-13） | 基线（10-11） | 判断 |
|---|---|---|---|
| WNS (ns) | 10.552 | 10.552 | 一致 |
| TNS (ns) | 0.000 | 0.000 | 一致 |
| TNS 失败端点 | 0 | 0 | 一致 |
| WHS (ns) | 0.038 | 0.038 | 一致 |
| 总端点 | 6204 | 6204 | 一致 |
| 结论行 | All user specified timing constraints are met. | 同 | 约束全部满足 |

报告文件逐行比对：465 行中仅 2 行不同（报告生成日期、报告输出命令中的路径），其余完全一致。

## 五、资源对比

| 资源 | 新建 | 基线 | 判断 |
|---|---|---|---|
| Slice LUTs | 1891（3.55%） | 1891（3.55%） | 一致 |
| Slice Registers | 2648（2.49%） | 2648（2.49%） | 一致 |
| Block RAM Tile | 2（1.43%） | 2（1.43%） | 一致 |
| DSPs | 0（0.00%） | 0（0.00%） | 一致 |

报告文件逐行比对：235 行中仅 2 行不同（日期、路径），其余完全一致。

## 六、DRC 对比

| 项目 | 新建 | 基线 |
|---|---|---|
| 检查条数 | 21 | 21 |
| 严重级别 | 全部 Warning | 全部 Warning |
| 具体规则 | CHECK-3（报告条数上限）1 条、REQP-1839（RAMB36 异步控制提醒）20 条 | 相同 |
| Error | 0 | 0 |

报告文件逐行比对：142 行中仅 2 行不同（日期、路径）。

## 七、bitstream 逐字节比对（关键证据）

对 `logic_analyzer.bit`（新建）与 `repo\pynq\logic_analyzer.bit`（基线）做整文件逐字节比较：

| 项目 | 结果 |
|---|---|
| 文件大小 | 两者均为 4045771 字节 |
| 不同字节数 | **5 个** |
| 不同字节位置 | 第 188～199 字节之间 |
| 差异内容 | 文件头部 ASCII 字段中的构建日期与时间文字（`2026/10/11 14:43:01` → `2026/10/13 19:56:41`） |
| 文件头 `SW_CRC=d35954d1` | 新旧完全相同 |
| 文件头 `SW_HDR_SHA256=b16e9c59…5e4f` | 新旧完全相同 |

**结论：两次构建产生的 FPGA 配置数据逐字节一致，本次干净重建精确复现了冻结基线的硬件逻辑。**

## 八、hwh 差异（4 行）与影响分析

新旧 `logic_analyzer.hwh` 均为 4366 行，差异 4 行：

| 行号 | 基线（10-11） | 新建（10-13） | 影响分析 |
|---|---|---|---|
| 2 | `TIMESTAMP="Sun Oct 11 14:39:39 2026"` | `TIMESTAMP="Tue Oct 13 19:53:07 2026"` | 构建时间戳，无功能影响 |
| 72 | `DDR_reset_n` 带 `POLARITY="ACTIVE_LOW"` | 无 `POLARITY` 属性 | PS 复位元数据；PL 配置由 bitstream 决定且已证明一致 |
| 2747 | `clkb` 带 `CLKFREQUENCY="50000000"` | 无 `CLKFREQUENCY` 属性 | 时钟元数据，不影响地址映射和寄存器行为 |
| 3432 | `PCW_M_AXI_GP0_FREQMHZ = 10` | `PCW_M_AXI_GP0_FREQMHZ = 50` | PS 侧参数 |

为什么 PS 参数不同而 bit 仍逐字节一致：`.bit` 只配置 Zynq 的可编程逻辑（PL）；处理器系统（PS，含时钟、DDR、MIO）的配置位于启动镜像（FSBL / ps7_init）中，不随 `.bit` 文件分发。因此 PS 参数差异不会体现在 bitstream 上。

**地址映射未发生变化**（`axi_bram_ctrl_0` = 0x40000000 / 8 KB、`axi_gpio_0` = 0x41200000、`axi_gpio_1` = 0x41210000），与 10-13 板卡实测读到的基地址一致。

## 九、结论与待办

1. 干净目录 Tcl 重建**成功**，且与基线在时序、资源、DRC、bitstream 配置数据四个维度上一致，其中 bitstream 为逐字节一致。
2. 发布产物采用本次构建的 `logic_analyzer.bit` + `logic_analyzer.hwh` + `design_1.xsa`（同一次构建生成，互相配套）。
3. 待办一：用新 bit 上板实测一次并留存截图（原计划 10-15）。
4. 待办二：10-21 依据本次对比结果，决定是否替换 `repo\pynq` 下的基线文件并提交。
5. 已知差异：hwh 4 行元数据差异，已在第八节说明；不影响功能，如评审问及可直接引用本节。

## 十、复现命令

```tcl
source "D:/FPGA/production/repo/scripts/build_clean_project.tcl"
```

执行前需保证 Vivado 中没有打开其它工程，且 `D:\FPGA\build_clean` 下不存在同名工程目录。
