# 模块讲解记录

每个成员写清自己主责模块的输入输出、关键机制，并各举一个具体例子。
第一阶段验收要求"每人能解释一个模块"，第二阶段交叉讲解后在此补充答辩要点。

## 队长：logic_analyzer_top 与系统数据通路

### 1. 这个模块是干什么的

`logic_analyzer_top` 是整机的顶层：把采样节拍、同步后的探针、控制字接进来，输出状态字，以及写 BRAM 用的地址、数据和写使能。它自己不存数据，数据存在外部的 Block RAM（BRAM）里。

### 2. 控制字（AXI GPIO 0，32 位输出）

| 位 | 名字 | 含义 |
|---|---|---|
| [0] | arm | 1 启动一次采集，需要从 0 变到 1 |
| [1] | clear | 1 清状态、清写指针和时间戳 |
| [3:2] | trigger_ch | 0~3，选哪一路做触发源 |
| [5:4] | trigger_mode | 0 上升沿，1 下降沿，2 任意边沿 |
| [15:6] | post_trigger | 触发后继续采的点数，最大 1023 |
| [25:16] | pre_trigger | 触发前保留的点数，最大 1023 |
| [31] | test_mode | 1 用内部测试计数，0 用 Pmod 输入 |

举例：`0x81004000` = test_mode=1、pre=256、post=256，其余位为 0。

### 3. 状态字（AXI GPIO 1，32 位输入）

| 位 | 名字 | 含义 |
|---|---|---|
| [0] | done | 采集完成，保持为 1，直到 clear |
| [1] | triggered | 已经检测到触发 |
| [12:2] | trigger_ptr | 触发点落在环形缓冲里的 11 位地址 |

举例：`0x00000403` = done=1、triggered=1、trigger_ptr=256。

### 4. 数据流（一句话版）

probe_i（或内部测试计数）→ sync_4ch 两级同步 → capture_engine 按 1 MSa/s 把一个 32 位字写进 BRAM 的 B 口 → PS 通过 AXI BRAM Controller 从 A 口读回 → Notebook 按 trigger_ptr 重排后画波形。

### 5. 地址映射（答辩"为什么用 AXI BRAM Controller"用这张表）

| 外设 | 地址 | 大小 |
|---|---|---|
| axi_bram_ctrl_0 | 0x40000000 | 8 KB = 2048 × 4 字节 |
| axi_gpio_0（控制） | 0x41200000 | 64 KB |
| axi_gpio_1（状态） | 0x41210000 | 64 KB |

用 AXI BRAM Controller 的原因：让 PS 的处理器像读写内存一样通过 AXI 总线直接访问 BRAM，不用自己写访问时序；BRAM 是真双端口，A 口给 AXI、B 口给采集逻辑，两边互不阻塞。

### 6. 每个采样字长什么样

{28 位时间戳, 4 位探针}，共 32 位。时间戳每个采样节拍加 1，clear 后从 0 开始，所以读取后低 4 位是 CH0~CH3，右移 4 位是时间戳。

## 队友A：sync_4ch、sample_divider 与触发验证

### 1. 这两个模块是干什么的

- `sync_4ch`：把 4 路外部异步探针信号同步到 `sys_clk` 时钟域，消除亚稳态，给采集引擎提供稳定的 `probe_sync[3:0]`。
- `sample_divider`：把 50 MHz 系统时钟分频成 1 MSa/s 的采样节拍 `sample_tick`，每个节拍只持续一个时钟周期，采集引擎据此写入一个样本。

我在团队里负责这两个模块、`logic_analyzer_tb.v`、时序/资源/DRC 汇总与边界测试。

### 2. sync_4ch：结构与时序

端口：`clk`、`rst_n`、`async_i[3:0]`、`sync_o[3:0]`。

内部是三级寄存器，全部标记 `ASYNC_REG = "TRUE"`：

```
async_i → meta → sync_reg → sync_o
```

- 第 1、2 级构成标准的**两级同步器**，用于降低亚稳态传播概率（提高 MTBF）；
- 第 3 级 `sync_o` 是输出寄存级，保证送到下游的组合逻辑（边沿检测）拿到的是干净、时序确定的信号；
- 因此从输入变化到 `probe_sync` 变化，总共是 **3 个时钟周期（60 ns @ 50 MHz）**。

实测例子（TBD-011 的 VCD）：`probe_i[0]` 在 24.250 µs 变高，`probe_sync[0]` 在 24.310 µs 变高，正好 3 拍。

补充：4 路是**相互独立的数字通道**，逐位同步是可接受的；如果未来采的是"必须保持位间一致"的并行总线，需要另做总线级同步或握手。

### 3. sample_divider：参数与行为

参数：`CLK_HZ = 50_000_000`、`SAMPLE_HZ = 1_000_000`、`CNT_WIDTH = 16`，分频系数 `DIV_VALUE = 50`。

行为：

```
counter == 49 ? (counter <= 0, sample_tick <= 1)
              : (counter <= counter + 1, sample_tick <= 0)
```

- `sample_tick` 是**单周期脉冲**，高电平持续 1 个时钟（20 ns）；
- 周期为 50 × 20 ns = **1 µs → 1 MSa/s**；
- 实测：VCD 中 `sample_tick` 每 1.000 µs 出现一次。

一个容易踩的坑（我在写边界测试时踩过）：`sample_tick` 是寄存器输出，采集引擎是在**下一个时钟沿**才看到 `sample_tick=1` 并处理该样本。所以 TB 里检查状态时，必须"等 tick 沿 + 再等一个 clk"才看得到写入/触发结果，否则会早一拍。

### 4. 触发是怎么实现的（答辩口径）

边沿检测（`capture_engine` 内）：

```
sel_now  = probe_sync[trigger_ch]
sel_prev = probe_sample_d[trigger_ch]      // 上一个采样节拍的值
rising   = sel_now & ~sel_prev
falling  = ~sel_now & sel_prev
any_edge = sel_now ^ sel_prev
edge_now = trigger_mode 选择 rising / falling / any_edge
```

触发条件：

```
trigger_event = sample_tick && state == S_RUN
             && history_count >= pre_trigger && edge_now
```

- `history_count >= pre_trigger` 保证触发点之前真的攒够了预触发数据；
- 命中时 `triggered <= 1`、`trigger_ptr <= wr_ptr`（记录触发时的写指针），然后进入 `S_POST`；
- `S_POST` 采满 `post_trigger` 个点后 `S_FLUSH`，下一拍 `S_DONE` 并置 `done=1`；
- `done` 是粘滞标志，只有 `clear` 能清零；`clear` 优先级高于 `arm`。

数据字：`{28 位时间戳, 4 位探针}`；写地址 `{wr_ptr, 2'b00}`，`wr_ptr` 到 2047 后回绕。软件按
`start = (trigger_ptr - PRE_TRIGGER) % DEPTH` 做 `np.roll(-start)`，取 `pre + post + 1 = 513` 个点。

### 5. 怎么验证的（可举证的实测结果）

主 Testbench（TBD-001，`tb/logic_analyzer_tb.v`）：

```
PASS: done=1, trigger_ptr=24
PASS: clear returned FSM to IDLE
```

边界测试（`tb/logic_analyzer_boundary_tb.v`，7 个用例、42 项断言，全部通过）：

| 编号 | 验证内容 | 关键结果 |
|---|---|---|
| TBD-004 | 无触发 | FSM 停留 `S_RUN`，`done=0`、`triggered=0`，缓冲持续写入（≥90 点） |
| TBD-011 | 上升沿 | 0→1 后 `triggered=1`，`trigger_ptr == wr_ptr` |
| TBD-012 | 下降沿 | 上升沿不误触发；1→0 后触发 |
| TBD-013 | 任意边沿 | 上升沿、下降沿均触发；稳定电平不触发 |
| TBD-014 | pre/post 组合 | 0/0、1/0、0/1、8/4 四组通过；触发后写入数分别为 0/0/1/4 |
| TBD-015 | 环形回绕 | 写地址 8188→0；`history_count` 封顶 2048；2100 次写入后 `wr_ptr=52`；回绕后仍能触发 |
| TBD-016 | 采集中 clear | `state→IDLE`，`done/triggered/wr_ptr` 清零；重新 arm 可再次采集 |

证据：`team/evidence/2026-10-19/TBD-00x_log.txt`（每个用例一份独立 xsim 日志）、
`team/boundary_test_table_2026-10-19.md`；时序/资源/DRC 见
`docs/timing_resource_drc_summary_2026-10-19.md`（WNS 10.552 ns、LUT 1891、FF 2648、BRAM 2、DRC 0 Error）。

### 6. 五分钟讲解提纲

1. **0:00–0:30** 角色与两个模块：同步 + 采样节拍。
2. **0:30–1:30** `sync_4ch`：三级寄存器、为什么两级同步 + 一级输出、3 拍延迟的实测例。
3. **1:30–2:30** `sample_divider`：DIV=50、单周期 `sample_tick`、1 MSa/s，以及"引擎晚一拍处理"的坑。
4. **2:30–4:00** 触发实现：边沿检测 → `history_ok` → `trigger_ptr` → POST/FLUSH/DONE；`done` 粘滞、`clear` 优先级。
5. **4:00–5:00** 验证证据：TBD-001 两条 PASS、TBD-004/011~016 共 42 项断言、时序资源数字。
6. **收尾**：边界（无超时逻辑、Pmod 输入未验证）。

### 7. 预设问答

- **Q：为什么两级同步还要加第三级？** 前两级解决亚稳态；第三级是输出寄存，保证扇出到边沿检测逻辑时时序干净、确定（总延迟 3 拍）。
- **Q：为什么 `sample_tick` 只高一个周期？** 一个节拍只应写一个样本；单周期脉冲避免重复写入。
- **Q：没有触发会怎样？** 状态机停在 `S_RUN`，`done=0`，环形缓冲持续覆盖；软件侧用超时（Notebook 为 5 s）判定异常。
- **Q：`pre_trigger` 能设多大？** 位域 10 位，最大 1023；`history_count` 封顶 2048，因此不会出现"永远等不到够历史"的情况。
- **Q：`post_trigger=0` 呢？** 触发后直接进 `S_FLUSH`，下一拍 `done=1`（TBD-014 的 0/0、1/0 用例已验证）。
- **Q：`clear` 和 `arm` 同时写会怎样？** `clear` 优先级更高，状态机回 `S_IDLE`，需要重新产生 `arm` 上升沿。
- **Q：板级 `trigger_ptr` 为什么有 256 和 257 两种？** 触发判定与采样节拍/输入相对相位有关，±1 个采样点属正常；TBD-005/009 记录中已注明 256~257 均正常。
- **Q：为什么用同步后的信号做边沿检测？** 直接比较异步输入会引入亚稳态和毛刺；同步后信号在时钟域内稳定。

### 8. 交叉讲解记录（2026-10-23）

- 讲解人：队友A
- 参与：队长、队友B
- 时长：5 分钟讲解 + 提问
- 内容：`sync_4ch` 同步机制、`sample_divider` 分频与单周期节拍、触发判定与边界验证
- 提问与回答：见上文「预设问答」中的前 5 条（现场提问已按相同口径回答）
- 结论：**通过**；队友A 能独立解释同步、分频与触发验证，并说明边界测试和资源数据

## 队友B：capture_engine 与 done

> 讲解记录：2026-10-24，主讲 田若溪，时长约 5 分钟，方式为对照 `rtl/capture_engine.v` 与 Notebook 实测结果讲解。

### 1. 这个模块是干什么的

`capture_engine` 是采集通路的核心：它按 `sample_tick` 把四路同步后的电平写进 2048 点的环形缓冲，判断触发条件，命中后继续采集后触发数据，最后用 `done` 通知软件「数据可以读了」。上游是 `sync_4ch` 给出的 `probe_sync` 和 `sample_divider` 给出的 `sample_tick`，下游是 `logic_analyzer_top` 里的 BRAM 端口。

参数为 `ADDR_WIDTH = 11`、`DEPTH = 2048`。

### 2. 控制字与状态字

控制字由 AXI GPIO 0 下发，位域与顶层一致：

| 位段 | 名称 | 含义 |
|---|---|---|
| ctrl[0] | arm | 上升沿启动一次采集 |
| ctrl[1] | clear | 复位状态机与指针，优先级高于 arm |
| ctrl[3:2] | trigger_ch | 触发通道 0~3 |
| ctrl[5:4] | trigger_mode | 0 上升沿、1 下降沿、2 任意边沿 |
| ctrl[15:6] | post_trigger | 后触发点数，上限 1023 |
| ctrl[25:16] | pre_trigger | 预触发点数，上限 1023 |
| ctrl[31] | test_mode | 1 用内部计数激励，0 用 Pmod 输入 |

状态字由 AXI GPIO 1 回读：`status[0]` 为 done，`status[1]` 为 triggered，`status[12:2]` 为 trigger_ptr。

### 3. 状态机

| 状态 | 跳出条件 | 行为 |
|---|---|---|
| S_IDLE | 检测到 arm 上升沿 | 清空写指针、计数器与时间戳 |
| S_RUN | 命中触发 | 每拍写一个样本；攒够 pre_trigger 之前不判触发 |
| S_POST | 采满 post_trigger | 继续写入触发之后的数据 |
| S_FLUSH | 下一拍 | 置位 done |
| S_DONE | 收到 clear | 保持 done=1，等待软件读走 |

### 4. 环形缓冲与 trigger_ptr

写指针从 0 递增到 2047 后回绕，缓冲里始终是最近 2048 个样本。触发点可能落在环中任意位置，所以模块在触发命中时把当前写指针记到 `trigger_ptr`。软件用 `start = (trigger_ptr - PRE_TRIGGER) % DEPTH` 算出起点，再做 `np.roll(arr, -start)`，取出 513 个有效样本，就能还原「触发前 256 点 + 触发点 + 触发后 256 点」的正确时间顺序。

### 5. 触发判定

先从 `probe_sync` 里按 `trigger_ch` 选出被观察通道，与上一拍采样值比较得到上升沿、下降沿、任意边沿三种信号，再由 `trigger_mode` 选择。另有 `history_ok = (history_count >= pre_trigger)` 作为门槛，保证触发点之前真的攒够了预触发数据。

### 6. done 为什么做成粘滞标志

软件读数据耗时不确定，如果 done 只给一拍脉冲，软件晚来一步就错过了。做成粘滞（保持到 clear 才清零）后，软件可以随时轮询 `status[0]`，读到 1 再读 BRAM，不会读到半截数据；读完后写 clear，状态机回到 IDLE，准备下一次采集。

### 7. 现场问答

**问：为什么要用 done，而不是固定延时？** 采集完成的时刻受触发位置影响，固定延时要么等太久要么读早了，done 是唯一可靠的同步点。

**问：`post_trigger = 0` 时怎么走？** 触发命中后直接进 S_FLUSH，不再采后触发点，有效样本为 pre_trigger + 1。

**问：`pre_trigger` 设得比已采样本多会怎样？** `history_ok` 一直为 0，状态机留在 S_RUN 继续写缓冲，直到攒够预触发数据才允许触发，因此不会出现前半段空数据。

**问：数据字里时间戳有什么用？** 每个样本是 `{28 位时间戳, 4 位探针}`，时间戳可以验证采样是否连续、定位触发时刻；1 MSa/s 下 28 位约 268 秒回绕，单次采集不会溢出。

**问：连续采集 10 次为什么都通过？** 每次 clear 把状态机和指针归零，arm 重新启动，实测 10 次全部 done=1、triggered=1，trigger_ptr 稳定在 256/257。

### 8. 一句话总结

`capture_engine` 用五状态机把「等触发、采数据、补后触发、报完成」串起来，环形缓冲加 `trigger_ptr` 解决了触发点不定位置的问题，`done` 则是软件与 PL 之间最关键的握手信号。
