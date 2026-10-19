# 边界测试表（TBD-004、TBD-011 ~ TBD-016）

- 测试日期：2026-10-19
- 被测版本：main `b2176ad`（RTL 与 `tb/logic_analyzer_tb.v` 自 `8aecd8e` 后未变）
- 仿真环境：Vivado Simulator 2026.1（`xvlog` / `xelab` / `xsim -R`）
- 测试台：`tb/logic_analyzer_boundary_tb.v`
- 复跑方式：
  - 全部用例：`xsim tb_boundary -R`
  - 单用例：`xsim tb_boundary -R -testplusarg CASE<n>`（如 `CASE4`、`CASE11` … `CASE16`）
- 证据：`team/evidence/2026-10-19/TBD-0xx.log`（每个用例单独运行的原始 xsim 输出，未手工编辑）
- 结果：**7 个用例全部通过，共 42 项断言，0 FAIL**

| 编号 | 场景 | 输入条件 | 预期 | 实际结果 | 证据 | 结论 |
|---|---|---|---|---|---|---|
| TBD-004 | 无触发 | probe 保持 0；pre=8 / post=4；运行 100 个采样点 | 不触发且状态明确 | FSM 停留 `S_RUN`；`history_count>=8`；`done=0`；`triggered=0`；环形缓冲持续写入 ≥90 点 | `TBD-004_log.txt`（5 项） | 通过 |
| TBD-011 | 上升沿 | `trigger_mode=0`，CH0 0→1 | 正确触发并记录 `trigger_ptr` | 低电平期间不触发；0→1 后 `triggered=1`；`trigger_ptr == wr_ptr`（触发点） | `TBD-011_log.txt`（3 项） | 通过 |
| TBD-012 | 下降沿 | `trigger_mode=1`，CH0 1→0 | 下降沿触发、上升沿不误触发 | 上升沿不触发；1→0 后 `triggered=1`；`trigger_ptr == wr_ptr` | `TBD-012_log.txt`（3 项） | 通过 |
| TBD-013 | 任意边沿 | `trigger_mode=2` | 两种边沿均触发 | 上升沿触发；稳定电平不触发；下降沿触发 | `TBD-013_log.txt`（3 项） | 通过 |
| TBD-014 | pre/post 组合 | 0/0、1/0、0/1、8/4 四组 | 触发正确；有效样本数 = pre+post+1；post 写入数正确 | 四组均正确触发并 `done`；触发后写入数分别为 **0 / 0 / 1 / 4**，与 post 一致 | `TBD-014_log.txt`（13 项） | 通过 |
| TBD-015 | 环形缓冲回绕 | arm 后先写入 2100 个采样点再触发 | 地址回绕、数据不丢、触发正确 | 写地址 `8188→0` 回绕；`history_count` 封顶 2048；`wr_ptr=52=2100 mod 2048`；回绕后仍能触发且 `done` | `TBD-015_log.txt`（7 项） | 通过 |
| TBD-016 | 采集中 clear | `S_RUN` 状态下写 `clear` | `done` 清零、回 IDLE、可重新 arm | `state→IDLE`；`done/triggered/wr_ptr` 全部清零；重新 arm 后再次触发并 `done` | `TBD-016_log.txt`（8 项） | 通过 |

## 判定说明

- **TBD-004**：设计中**没有超时逻辑**，因此"未触发状态明确"定义为：`done=0`、`triggered=0`、FSM 停留 `S_RUN`、环形缓冲继续写入。
- 以上均为**仿真验证**（Vivado xsim），不含板级复验；如需板级确认，另行安排。
- `trigger_ptr` 的判定采用"触发时刻 `wr_ptr` 快照"作为期望值，避免依赖固定采样计数器。
- 共享测试记录（`team/test_record_template.csv`）按队长要求由其统一更新，本表作为其输入。

## 用例与断言统计

| 用例 | 断言数 |
|---|---|
| TBD-004 | 5 |
| TBD-011 | 3 |
| TBD-012 | 3 |
| TBD-013 | 3 |
| TBD-014 | 13 |
| TBD-015 | 7 |
| TBD-016 | 8 |
| **合计** | **42** |