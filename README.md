# RC4 Hardware Decryption System (FPGA)

This project implements the **RC4 stream cipher** on an **Intel DE1-SoC FPGA**, using SystemVerilog. The system performs key scheduling, pseudo-random generation, and real-time decryption of an encrypted message stored in ROM. The design also includes a **brute-force key cracker** to recover the original key based on expected plaintext properties.

---

## Project Overview

- **Goal**: To design and implement a hardware pipeline that decrypts a 32-character RC4-encrypted message stored in ROM using an unknown 24-bit key.
- **Platform**: Intel DE1-SoC FPGA Board (Quartus Prime)
- **Language**: SystemVerilog (with VHDL IPs used where applicable)
- **Cipher**: RC4 Stream Cipher
- **Decryption Success Criteria**: Decrypted message consists of lowercase letters (`a`–`z`) and spaces only

---

## Modules Overview

### `s_memory_shuffle` — KSA (Key Scheduling Algorithm)
- Initializes and permutes the 256-byte `S` array based on a 24-bit key
- Performs 256 rounds of swapping using the key

### `decrypter` — PRGA (Pseudo-Random Generation Algorithm)
- Performs real-time generation of keystream bytes
- XORs each keystream byte with ROM data to produce decrypted output in RAM

### `cracker` — Brute-force Key Search
- Iterates through all possible 24-bit keys (up to `0x3FFFFF`)
- Flags when the decrypted output contains only valid characters (a–z, space)
- Asserts `found` or `not_found` when complete

### `ksa - top module` — Integration
- Manages sequencing between initialization, shuffling, decryption, and cracking
- Controls write enable lines and multiplexes memory addresses/data

---

## Building

### Requirements
- Quartus Prime 16.1 (tested on Lite Edition)
- ModelSim (for simulation)
- DE1-SoC FPGA board

### Steps
1. Clone this repository.
   
2. Open the Quartus project file in /project and compile.

3. Load the .sof onto the DE1-SoC board using the Quartus Programmer.
