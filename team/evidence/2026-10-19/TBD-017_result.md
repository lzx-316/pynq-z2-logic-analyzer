# TBD-017 发布候选 bit/hwh 板级 smoke test

日期：2026-10-19
负责人：队长
测试对象：`repo/pynq` 中的 2026-10-19 干净重建发布候选文件

## 使用文件

- `logic_analyzer.bit`
- `logic_analyzer.hwh`
- `notebooks/logic_analyzer_corrected.ipynb`

## 测试结果

- Overlay 加载成功
- `IP list`：`axi_gpio_0`、`axi_gpio_1`、`processing_system7_0`
- `control idle = 0x81004000`
- `done=1`
- `triggered=1`
- `trigger_ptr=257`
- `valid samples=513`
- CSV：513 行、6 列（`index,timestamp,ch0,ch1,ch2,ch3`）
- 连续采集：10/10 通过
- `trigger_ptr` 范围：256 至 257
- 4 通道波形正常

## 证据文件

- `TBD-017_overlay_ok.png`
- `TBD-017_status.png`
- `TBD-017_valid_samples.png`
- `TBD-017_waveform_4ch.png`
- `TBD-017_csv_saved.png`
- `TBD-017_repeat_10.png`
- `TBD-017_logic_capture.csv`

## 结论

发布候选 bit/hwh 已在实际 PYNQ-Z2 上完成加载和采集验证，TBD-017 通过。
