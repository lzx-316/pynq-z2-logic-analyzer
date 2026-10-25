# 10/23 交叉讲解补充问答记录

- 记录日期：2026-10-23（补充整理：2026-10-25）
- 讲解人：队友A
- 范围：`sync_4ch`、`sample_divider`、触发与验证，以及与 `capture_engine` / Notebook 的衔接
- 用途：交叉讲解现场未展开的问题、以及最终回归阶段新增的版本/复现问题

## A. 同步与采样

**Q1：为什么同步器是 3 拍，不是 2 拍？**
前两级（`meta`、`sync_reg`）构成标准两级同步器，用于降低亚稳态传播概率；第三级 `sync_o` 是输出寄存，保证送到边沿检测逻辑的信号时序干净、扇出确定。总延迟 = 3 个时钟（60 ns @ 50 MHz）。

**Q2：`sample_tick` 只高一个周期，采集引擎为什么"晚一拍"才处理？**
`sample_tick` 是寄存器输出，它在本时钟沿变 1；采集引擎在**下一个时钟沿**读到 `sample_tick=1` 才写入样本。
所以 TB 里检查状态必须"等 tick 沿 + 再等一个 clk"，否则会早一拍（我在写边界测试时踩过这个坑）。

**Q3：如果输入边沿发生在两个采样节拍之间，会怎样？**
不会被记录。系统是 1 MSa/s 采样，只能看到每个采样点上的电平；窄于 1 µs 的脉冲可能被漏采（这是采样率的物理限制，不是同步器问题）。

**Q4：为什么用 `probe_sync` 和 `probe_sample_d` 比较来判边沿？**
`probe_sync` 是当前采样点的值，`probe_sample_d` 是上一个采样点的值；两者异或/与运算即可得到上升沿、下降沿、任意边沿。比较发生在采样节拍上，因此边沿判定的分辨率就是 1 个采样周期。

## B. 触发与状态机

**Q5：`history_count >= pre_trigger` 是干什么的？**
保证触发命中时，触发点之前已经攒够了 `pre_trigger` 个样本，软件才能还原出完整的"前 256 点"窗口。`history_count` 封顶 2048，`pre_trigger` 最大 1023，因此不会出现永远等不到的情况。

**Q6：`clear` 和 `arm` 同时写会怎样？**
`clear` 优先级更高：状态机回 `S_IDLE`，`done/triggered/wr_ptr` 全部清零，需要重新产生 `arm` 上升沿。TBD-016 已验证。

**Q7：`done` 为什么做成粘滞？**
软件轮询有时间抖动，粘滞标志保证任何时刻读都不会漏掉"采集完成"事件；只有 `clear` 能清零。

**Q8：板级 `trigger_ptr` 为什么会有 256 和 257 两种？**
触发判定与采样节拍、输入相对相位有关，±1 个采样点属正常范围；TBD-005/009 的记录里已注明 256~257 均正常。

**Q9：没有触发会怎样？**
状态机停在 `S_RUN`，`done=0`、`triggered=0`，环形缓冲持续覆盖；软件侧用超时判断（Notebook 为 5 s）。TBD-004 已验证该行为。

## C. 数据通路与软件

**Q10：为什么是 513 个有效点？**
`pre_trigger + 触发点本身 + post_trigger = 256 + 1 + 256 = 513`。软件用 `start = (trigger_ptr - PRE_TRIGGER) % DEPTH` 做 `np.roll(-start)`，再取前 513 点。

**Q11：Notebook 怎么知道寄存器地址和 IP 名？**
通过同名 `.hwh`：`Overlay("logic_analyzer.bit")` 会自动加载 `logic_analyzer.hwh`，`ol.ip_dict` 里就是 `axi_gpio_0`、`axi_gpio_1`、`axi_bram_ctrl_0`。地址映射（BRAM `0x40000000`、GPIO0 `0x41200000`、GPIO1 `0x41210000`）与 hwh 一致。

**Q12：Notebook v1 和 v2 有什么区别？应该用哪个？**
v2 按 7 个步骤输出状态并带运行汇总，`write_ctrl()` 同时兼容 `write(value, mask)` 和 `write(value)` 两种签名；v1 目前也已使用双参数写法。正式演示用 **v2**。

## D. 版本与复现（最终回归新增）

**Q13：怎么证明 bit/hwh/XSA 是配套的？**
把 XSA 解开，`design_1.bit` / `design_1.hwh` 与 `pynq/logic_analyzer.bit` / `.hwh` 逐字节一致（SHA256 相同）；hwh 时间戳 `Mon Oct 19 12:23:48 2026` 与三份报告的 `12:27:22~26` 属同一构建会话。

**Q14：怎么证明板级证据对应的是发布 bit？**
TBD-017 使用的就是当前 `pynq/` 的 bit/hwh（git blob `92e44f0f` / `fabe4fff`）；bit 的 SHA256 为
`2c1ee29d20f246e7f19c61980f80cf7eb3d16671e88d6464a1d82f190f2eba20`。注意：TBD-017 的证据截图里没有
板端 `sha256sum` 输出，这一点已记录为 P2，后续可补。

**Q15：DRC 的 20 条 REQP-1839 和 1 条 CHECK-3 是什么？**
`REQP-1839` 是 RAMB36 异步控制检查的 Warning（与 10-11 基线完全相同，属既有告警）；`CHECK-3` 是"报告规则上限"提示（因 REQP-1839 达到 20 条上限）。**0 Error**，设计 `Fully Routed`。

**Q16：工程能脱离原目录重建吗？**
能。独立重建（TBD-018）在自己的环境、全新目录用 Tcl 复现，结果与队长构建一致；hwh 除 `TIMESTAMP` 外逐行相同。
注意 `scripts/build_clean_project.tcl` 里的 `repo_scripts` 是绝对路径，换机器时需改本地路径（不修改仓库脚本，只改临时副本）。

**Q17：发布说明（PR #18）、最终回归报告（PR #19）和版本一致性是什么关系？**
三者用同一套数据：发布说明引用 10-19 干净重建的产物与测试结果；最终回归报告在最新 main 上复跑仿真并逐项核对
bit/hwh/XSA/报告/Notebook/Tcl 的指纹；版本一致性检查是这两份文档的依据。三者数字必须一致（WNS 10.552、
LUT 1891、FF 2648、BRAM 2、DRC 0 Error，20+1 Warning）。

**Q18：如果 bit 和 hwh 不配套，会出什么问题？怎么发现？**
Overlay 会按 hwh 的 IP 名/地址去访问 PL，若 hwh 与 bit 不是同一轮构建，可能出现 IP 找不到、地址越界或读回数据异常。
发现方法：解开 XSA，比较其中的 `design_1.bit` / `design_1.hwh` 与 `pynq/` 两份的 SHA256；再核对 hwh 的
`TIMESTAMP` 与报告的 `Date` 是否属同一构建会话（本次为 12:23:48 与 12:27:22~26）。

## E. 结论

以上问答覆盖同步、分频、触发、数据还原、Notebook 和版本一致性；证据均可在 `team/evidence/`、
`docs/timing_resource_drc_summary_2026-10-19.md` 与 `docs/final_regression_report_2026-10-25.md` 中找到。