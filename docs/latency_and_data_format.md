# Latency and Data Format

This document describes the data representation and timing behavior
of the Gain module.

---

## Data Format

### Audio Samples
- Signed 16-bit
- Two’s complement
- Interleaved stereo (AXI-Stream)

### Gain Values
- Signed fixed-point Q4.12
- Stored in 16 LSBs of AXI-Lite registers

---

## Latency

### Core (`gain_core`)
- 1 clock cycle latency
- Registered output
- Clock-enable controlled

### AXI Wrapper
- Adds one pipeline stage for AXI-Stream compliance
- Total end-to-end latency: **2 clock cycles**

Latency is:
- Fixed
- Deterministic
- Independent of gain value

---

## AXI-Stream Behavior

- `tready` propagation prevents deadlock
- Output registers hold data during backpressure
- `tlast` is delayed in sync with data

---

## Timing Assumptions

- Single clock domain
- No clock domain crossing
- Reset is synchronous to AXI clock

These assumptions are documented explicitly to avoid ambiguity.
