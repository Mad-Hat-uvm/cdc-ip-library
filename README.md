cdc-ip-library
==============

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Build](https://img.shields.io/badge/build-passing-brightgreen)
![Coverage](https://img.shields.io/badge/coverage-90%25-green)
![Last Commit](https://img.shields.io/github/last-commit/Mad-Hat-uvm/cdc-ip-library)
![Repo Size](https://img.shields.io/github/repo-size/Mad-Hat-uvm/cdc-ip-library)
![AI-Assisted](https://img.shields.io/badge/AI-Assisted-green)

Reusable **Clock Domain Crossing (CDC)** IP blocks with synthesizable SystemVerilog RTL, **UVM testbenches**, functional coverage, and SVA checks.  

This repository is a collection of **industry-grade CDC primitives** that can be used as black-box IP in ASIC/FPGA flows and verified through both simulation and formal techniques.  

---

✨ IP Blocks
------------

| IP                     | Purpose                                         | Status      |
|-------------------------|-------------------------------------------------|-------------|
| `cdc_sync_2ff`         | Standard 2-FF synchronizer for single-bit signals | ✅ Complete |
| `cdc_reset_sync`       | Reset deassertion synchronizer (async assert, sync deassert) | ✅ Complete |
| `cdc_pulse_sync`       | Pulse synchronizer for narrow pulses            | 🚧 Planned  |
| `cdc_handshake_sync`   | Req/Ack handshake synchronizer for multi-bit transfers | 🚧 Planned  |
| `cdc_mailbox_async_fifo` | Parameterized asynchronous FIFO with Gray pointers | 🚧 Planned  |

---

🗂️ Repository Structure
------------------------

ngle-bit signals | ✅ Complete |
| `cdc_reset_sync`       | Reset deassertion synchronizer (async assert, sync deassert) | ✅ Complete |
| `cdc_pulse_sync`       | Pulse synchronizer for narrow pulses            | 🚧 Planned  |
| `cdc_handshake_sync`   | Req/Ack handshake synchronizer for multi-bit transfers | 🚧 Planned  |
| `cdc_mailbox_async_fifo` | Parameterized asynchronous FIFO with Gray pointers | 🚧 Planned  |

---

🗂️ Repository Structure
------------------------
rtl/ # RTL design files
cdc_sync_2ff.sv
cdc_reset_sync.sv
cdc_pulse_sync.sv
cdc_handshake_sync.sv
cdc_mailbox_async_fifo.sv

tb/ # Testbenches
uvm_env/
agents/
scoreboard.sv
coverage.sv
tests/
simple_tb/

sva/ # Assertions
cdc_sync_2ff_assert.sv
cdc_fifo_assert.sv

scripts/ # Scripts and constraints
Makefile
run_sim.py
sdc/

docs/ # Documentation
README.md
spec.md
usage.md
verification_plan.md


---

🔌 Example: 2-FF Synchronizer
-----------------------------

```systemverilog
module cdc_sync_2ff #(
  parameter int STAGES = 2
)(
  input  logic clk,
  input  logic arst_n, // async assert, sync deassert
  input  logic d,
  output logic q
);

Default = 2 stages (classic synchronizer)

Configurable stages for higher MTBF

Synthesis attribute (* ASYNC_REG="TRUE" *) applied

🧪 Verification

Strategy

Module-level tests with randomized clock ratios

UVM environment for multi-clock IPs (FIFO, handshake)

Scoreboard with golden reference queue

Assertions (SVA) to enforce safety properties

Functional coverage across clock ratios, FIFO occupancy, resets, and pulse widths

Assertions (examples)

// No write when FIFO is full
property no_overflow;
  @(posedge wclk) disable iff (!wrst_n) !(w_en && w_full);
endproperty
a_no_overflow: assert property(no_overflow);

// No read when FIFO is empty
property no_underflow;
  @(posedge rclk) disable iff (!rrst_n) !(r_en && r_empty);
endproperty
a_no_underflow: assert property(no_underflow);

🤖 AI Integration

AI-generated documentation: Summaries and diagrams auto-created for each CDC block

Testcase generation: Use LLMs to propose additional corner cases

Log summarization: Scripts that parse simulation logs and provide human-readable root causes

Tutor mode: Explanations of CDC concepts in simple language for learners

Badge example:


🧭 Roadmap

 cdc_sync_2ff

 cdc_reset_sync

 cdc_pulse_sync

 cdc_handshake_sync

 cdc_mailbox_async_fifo

 UVM regression environment

 Functional coverage closure

 Formal properties (SymbiYosys/Jasper)

 AI integration tools (doc generation, log summarizer, testcase assistant)

🚀 Quick Start
# Clone
git clone https://github.com/<yourname>/cdc-ip-library
cd cdc-ip-library

# Run smoke test
make SIM=questa TEST=smoke

📜 License

MIT License – free to use in academic and professional projects.

📖 References

Cliff Cummings, “Clock Domain Crossing (CDC) Design & Verification Techniques”

Xilinx/Intel FPGA CDC application notes

UVM Class Reference Guide

