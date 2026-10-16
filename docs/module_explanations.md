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

## 队友B：capture_engine 与 done（待补）