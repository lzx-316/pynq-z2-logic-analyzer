# 术语表

| 术语 | 英文 | 说明 |
|---|---|---|
| 逻辑分析仪 | Logic Analyzer | 同时采集多路数字信号并按时序显示的工具，本项目实现 4 通道版本 |
| 采样 | Sampling | 在被测信号上按固定时间间隔取点，取到的每一个点称为一个样本 |
| 采样率 | Sample Rate | 每秒采集的样本数，本设计固定为 1 MSa/s |
| 采样时钟分频 | Sample Clock Divider | 把系统时钟分频得到采样使能，本设计为 50 MHz ÷ 50 = 1 MHz |
| 采样使能 | sample_tick | 单周期脉冲，每个脉冲采集并写入一个样本 |
| 存储深度 | Buffer Depth | 一次采集能保存的样本数，本设计固定 2048 点 |
| 环形缓冲 | Ring Buffer | 写满后从头部覆盖的缓冲区，保证总是保存最近的数据 |
| 预触发 | Pre-trigger | 触发点之前保留的样本数，本设计上位机默认取 256 点 |
| 后触发 | Post-trigger | 触发之后继续采集的样本数，默认 256 点 |
| 触发 | Trigger | 让采集停止并使数据定格的条件 |
| 上升沿触发 | Rising-edge Trigger | 被观察通道由 0 变 1 时触发 |
| 下降沿触发 | Falling-edge Trigger | 被观察通道由 1 变 0 时触发 |
| 任意边沿触发 | Any-edge Trigger | 只要电平发生变化就触发 |
| 触发点 | Trigger Point | 命中的那个样本，其所在地址由 trigger_ptr 给出 |
| 时间戳 | Timestamp | 每个样本附带的计数，本设计为 28 位，1 MSa/s 下约 268 秒回绕 |
| 亚稳态 | Metastability | 异步信号在时钟边沿附近变化导致触发器输出不确定的现象 |
| 同步器 | Synchronizer | 用两级触发器把异步输入打拍到本地时钟域，降低亚稳态传播风险 |
| 块存储器 | Block RAM (BRAM) | FPGA 内部专用存储资源，本设计用 2 块 BRAM 存放样本 |
| 通用输入输出 | AXI GPIO | PS 侧通过 AXI 总线读写 PL 寄存器的 IP，本设计用它下发控制字、回读状态字 |
| 覆盖层 | Overlay | PYNQ 中加载到 PL 的硬件设计，对应 .bit 与 .hwh 两个文件 |
| 位流文件 | Bitstream (.bit) | PL 的配置文件，加载后 FPGA 才具备该功能 |
| 硬件握手文件 | .hwh | 描述 IP 地址与寄存器信息的文件，Overlay 依赖它与 .bit 同名同目录 |
| 测试模式 | TEST_MODE | 置 1 时 PL 内部产生计数激励，用于无外部信号时验证链路 |
| 引脚约束 | XDC | 指定引脚位置与电平标准的约束文件，本设计使用 Pmod A 的 Y18/Y19/Y16/Y17 |
| 综合与实现 | Synthesis / Implementation | 把 RTL 转换成 FPGA 可配置文件的过程 |
| 时序收敛 | Timing Closure | 建立、保持、脉宽三类检查全部满足，即 Worst Slack 为正 |
| 最差建立余量 | WNS | Worst Negative Slack，本设计为 10.552 ns，约束全部满足 |
| 资源利用率 | Utilization | 设计占用的 LUT、寄存器、BRAM 等资源比例，本设计 LUT 3.55%、寄存器 2.49% |
| 设计规则检查 | DRC | 检查设计是否存在违规，本设计状态为 Fully Routed 且无未处理违规 |
| 测试平台 | Testbench | 用仿真方式驱动被测模块并自动判定结果的 Verilog 代码 |
