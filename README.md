# MIPS Multi-Cycle Processor (SystemVerilog)

## 📌 Project Overview

A synthesizable **Multi-Cycle MIPS32 Processor** implemented in **SystemVerilog**, following the classical multi-cycle architecture approach described in computer architecture literature.

The processor executes each instruction over multiple clock cycles, enabling hardware resource reuse (ALU, memory) and significantly reducing area compared to single-cycle implementations.

This project focuses on clean RTL design, modular hierarchy, and accurate control sequencing using a Moore FSM.

---

## 🏗 Architecture

### 🔹 Datapath
- Single shared ALU for:
  - PC increment (PC + 4)
  - Branch target calculation
  - Memory address computation
  - R-type arithmetic/logic operations
- Unified instruction & data memory
- Register file (32 × 32-bit)
- Dedicated pipeline registers:
  - IR (Instruction Register)
  - MDR (Memory Data Register)
  - A/B registers
  - ALUOut register

### 🔹 Control Unit
- Moore Finite State Machine (12 states)
- Explicit separation between:
  - Instruction Fetch
  - Decode
  - Execute
  - Memory Access
  - Write-back
- Clean control signal generation:
  - RegWrite
  - MemWrite
  - MemRead
  - ALUSrcA / ALUSrcB
  - PCSource
  - IorD
  - IRWrite
  - PCWrite / PCWriteCond

---

## 🧠 Supported Instructions

### R-Type (4 cycles)
- add
- sub
- and
- or
- slt

### I-Type
- addi (4 cycles)
- lw (5 cycles)
- sw (4 cycles)
- beq (3 cycles)

### J-Type
- j (3 cycles)

---

## ⏱ Instruction Latency

| Instruction | Cycles |
|------------|--------|
| R-Type     | 4      |
| addi       | 4      |
| lw         | 5      |
| sw         | 4      |
| beq        | 3      |
| j          | 3      |

---

## 🛠 Tools & Environment

- **Language:** SystemVerilog (IEEE 1800)
- **Design Style:** Synthesizable RTL
- **Simulator:** Cadence Xcelium (`xrun`)
- **Waveform Debug:** SimVision
- **Target:** ASIC-style RTL development flow

---


