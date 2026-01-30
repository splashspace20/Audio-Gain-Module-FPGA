# Design Rationale

This document explains **why the Gain module is implemented the way it is**.

The goal is clarity of intent, not maximal configurability.

---

## Fixed-Point Arithmetic

- Audio data: signed 16-bit PCM
- Gain format: Q4.12

Reasons:
- Deterministic behavior
- Simple scaling
- Predictable saturation
- Efficient mapping to FPGA DSP resources

Floating-point was intentionally avoided.

---

## Saturation Strategy

Saturation is applied:
- After fixed-point scaling
- Before truncation to 16-bit output

This prevents:
- Wraparound distortion
- Undefined behavior on overflow

The output is bounded to:
- +32767
- −32768

---

## Bypass Mode

Bypass is implemented explicitly in RTL rather than via gain = 1.0.

Benefits:
- Zero arithmetic activity
- Clear functional intent
- Easy verification

---

## AXI Integration

The design separates concerns:
- `gain_core`: arithmetic and saturation only
- `axis_gain_wrapper`: AXI-Stream + AXI-Lite integration

This separation:
- Simplifies testing
- Improves reuse
- Keeps core logic readable

---

## What This Design Is NOT

- Not a full audio processing framework
- Not parameterized for all bit-widths
- Not optimized for extreme throughput

These are conscious trade-offs aligned with the repository’s purpose.
