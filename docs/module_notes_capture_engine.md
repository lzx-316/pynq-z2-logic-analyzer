# 模块讲解记录：capture_engine 与 done 信号

## 一、模块定位

`rtl/capture_engine.v` 是采集通路的核心，负责把 4 通道采样值写入 Block RAM、判定触发、并在采集结束后告诉上位机数据就绪。上游是 `sync_4ch`（同步后的 4 位探针值 `probe_sync`）和 `sample_divider`（采样使能 `sample_tick`），下游是 `logic_analyzer_top` 里的 BRAM 端口。

参数：`ADDR_WIDTH = 11`、`DEPTH = 2048`。

## 二、端口与寄存器映射

控制字 `ctrl` 来自 AXI GPIO 的 channel1，位域分配如下：

| 位段 | 名称 | 说明 |
|---|---|---|
| `ctrl[0]` | arm | 上升沿启动一次采集 |
| `ctrl[1]` | clear | 复位状态机与所有指针，优先级高于 arm |
| `ctrl[3:2]` | trigger_ch | 触发通道，0~3 对应 CH0~CH3 |
| `ctrl[5:4]` | trigger_mode | 0 上升沿、1 下降沿、2 任意边沿，3 保留 |
| `ctrl[15:6]` | post_trigger | 触发后继续采集的采样点数，上限 1023 |
| `ctrl[25:16]` | pre_trigger | 触发点之前保留的采样点数，上限 1023 |
| `ctrl[31]` | test_mode | 1 用内部计数器作激励，0 用 Pmod 外部输入 |

状态字 `status` 回读给 AXI GPIO 的 channel1：

| 位段 | 名称 | 说明 |
|---|---|---|
| `status[0]` | done | 采集完成标志，粘滞，直到 clear 才清零 |
| `status[1]` | triggered | 本次采集是否真的命中触发条件 |
| `status[12:2]` | trigger_ptr | 触发点样本在环形缓冲中的写入地址 |

## 三、状态机

| 状态 | 跳出条件 | 该状态下做什么 |
|---|---|---|
| `S_IDLE` | 检测到 `arm` 上升沿 | 清空写指针、后触发计数、历史计数与时间戳 |
| `S_RUN` | 命中触发事件 | 每个 `sample_tick` 写一个样本并递增时间戳；达到 `pre_trigger` 之前不判触发 |
| `S_POST` | 采满 `post_trigger` 个点 | 继续写入触发点之后的数据 |
| `S_FLUSH` | 下一拍自动跳转 | 把 `done` 置 1 |
| `S_DONE` | 收到 `clear` | 保持 `done = 1`，等待上位机读走数据 |

## 四、三个关键机制

环形缓冲：写指针 `wr_ptr` 从 0 递增到 `DEPTH - 1` 后回绕到 0，因此缓冲里永远保留最近 2048 个样本。因为触发点落在环形缓冲的任意位置，所以模块额外输出 `trigger_ptr` 记录触发时写指针的位置，上位机用它对采样序列做循环移位，就能还原出「触发点之前 pre_trigger 个点 + 触发点 + 之后 post_trigger 个点」的正确时间顺序。

触发判定：先从 `probe_sync` 里按 `trigger_ch` 选出被观察通道，与上一拍的采样值比较得到三种边沿，再由 `trigger_mode` 选择使用哪一种。另外设置了 `history_ok = (history_count >= pre_trigger)` 这一道门槛，保证触发点之前确实攒够了预触发数据，否则前段波形会是空的。

数据打包：每个样本在 BRAM 里占一个 32 位字，低 4 位是 4 个通道的采样值，高 28 位是该样本的时间戳，由 `{timestamp, probe_sync}` 拼成。1 MSa/s 下 28 位时间戳约 268 秒回绕一次，单次采集远小于这个长度，不会产生歧义。

## 五、done 信号的作用与验证方法

`done` 是软件与 PL 之间的同步点。上位机 arm 之后不再靠固定延时猜时间，而是轮询 `status[0]`，一旦置 1 再去读 BRAM，这样无论采集快慢都不会读到半截数据。`done` 设计成粘滞标志是有意为之：软件读数据的耗时不确定，粘滞可以让它在任意时刻多次查询都不会漏掉完成事件，只有写完控制字 `clear` 才回到 0。

仿真验证（`tb/logic_analyzer_tb.v`）：先给 `clear` 脉冲让状态机回到 IDLE，再给 `arm` 脉冲启动，随后在 CH0 上制造一个上升沿，等待若干周期后检查 `status[0]` 是否为 1，最后再发一次 `clear` 检查 `done` 是否被清掉。两条打印分别为 `PASS: done=1, trigger_ptr=...` 和 `PASS: clear returned FSM to IDLE`。

## 六、讲解时值得强调的两个细节

`clear` 的优先级高于 `arm`：控制字里两个位同时置 1 时，状态机优先执行清零，避免上一轮的数据混进新一轮采集。

仿真时钟与设计的差异：测试平台里 `forever #5 clk = ~clk` 得到的是 100 MHz 时钟，而 `sample_divider` 的 `CLK_HZ` 参数按 50 MHz 填写，所以仿真中实际的采样间隔对应 2 MSa/s，而不是板上的 1 MSa/s。汇报时要么把测试平台的半周期改成 `#10`，要么在报告里明确说明这是仿真时钟差异，不要写成「仿真验证了 1 MSa/s」。
