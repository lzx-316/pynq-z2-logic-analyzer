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

## 队友A：sync_4ch 与 sample_divider（待补）

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
