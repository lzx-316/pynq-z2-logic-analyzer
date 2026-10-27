---
name: pynq-logic-analyzer
description: >
  Use when working on the PYNQ-Z2 four-channel logic analyzer project
  (lzx-316/pynq-z2-logic-analyzer): loading the bitstream, running the
  Jupyter notebook, collecting TBD evidence, or writing/verifying the report.
  Covers bit/hwh pairing, the 1 MSa/s sampling model, the 2048-point ring
  buffer, trigger_ptr reordering, done handshaking and the evidence contract.
---

# PYNQ-Z2 Logic Analyzer Workflow

## When to use

Use this skill for any task in the `pynq-z2-logic-analyzer` repository:
running the board demo, re-collecting evidence, checking report numbers,
or onboarding a new teammate to the notebook flow.

## Hard facts (do not invent alternatives)

- Sampling rate is fixed in RTL: `50 MHz ÷ 50 = 1 MSa/s`. The notebook has no
  sample-rate parameter.
- Buffer depth is fixed at 2048 points; pre-trigger and post-trigger default to
  256 each, valid window is `pre + post + 1 = 513` samples.
- Trigger modes are 0 rising, 1 falling, 2 any edge. There is no level trigger.
- `status[0]` is done, `status[1]` is triggered, `status[12:2]` is trigger_ptr.
- Every BRAM word is `{28-bit timestamp, 4-bit probes}`.
- `sync_4ch` uses three registers (`meta → sync_reg → sync_o`), so the input to
  output latency is **3 clock cycles**, not 2.
- `AxiGPIO.Channel.write` may require an explicit mask on newer PYNQ images.
  Use the `write_ctrl()` wrapper from `notebooks/logic_analyzer_v2.ipynb`.

## Board procedure

1. Connect the board by Ethernet, set the PC NIC to `192.168.2.100/24`.
2. Open `http://192.168.2.99:9090` and log in as `xilinx` / `xilinx`.
3. Upload `pynq/logic_analyzer.bit`, `pynq/logic_analyzer.hwh` and the notebook
   into one folder; the `.bit` and `.hwh` must share the same base name.
4. Run the notebook top to bottom with `TEST_MODE = 1`.
5. Expect `ctrl_idle = 0x81004000`, `done=1`, `triggered=1`,
   `trigger_ptr` in 256..257, `valid samples: 513`, `PASS 10/10`.

## Evidence contract

- Save screenshots/CSVs under `team/evidence/YYYY-MM-DD/` with the test id as
  prefix (`TBD-0xx_*`).
- Update `team/test_record_template.csv` in the same commit.
- Never mark a test as passed without a file in `team/evidence/`.
- Do not commit the Vivado project directory or personal copies of bit/hwh.

## Boundaries

- Do not modify RTL when the task is documentation or reporting.
- Do not claim 100 MHz sampling or level triggering; both are out of scope.
- Do not run the notebook from a PC-local Jupyter; the Overlay must load on the
  PYNQ board.
