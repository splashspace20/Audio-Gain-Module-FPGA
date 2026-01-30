# Build Overview

This repository focuses on **RTL architecture and verification**.
The build flow is intentionally split into **reproducible** and
**documented-only** stages.

---

## What Is Reproducible

The following steps can be recreated directly from this repository:

1. RTL compilation
2. SystemVerilog simulation
3. Waveform inspection
4. CSV-based result analysis

Artifacts provided:
- RTL sources
- Testbenches
- Minimal Vivado Tcl scripts
- Simulation outputs (CSV + plots)

---

## What Is Documented (Not Recreated)

The following steps were performed during development but are **not**
recreated via scripts in this repository:

- Full Block Design recreation
- Bitstream generation
- PYNQ overlay packaging
- Python runtime control code

These steps are intentionally omitted to keep the repository focused on
**RTL design decisions**, not software plumbing.

---

## Vivado Usage

- Vivado is used for:
  - RTL elaboration
  - Simulation
  - Synthesis sanity checks
- A minimal `create_project.tcl` is provided for convenience.

---

## Hardware Validation

Hardware validation was performed on:
- **AMD Kria KV260**
- Using **PYNQ overlay**

The validation confirmed:
- Correct AXI handshaking
- Correct gain behavior
- Stable operation under streaming conditions

The bitstream and overlay files are not published by design.
