# FPGA-based Digital Clock & Stopwatch System

## Project Overview
This project presents a comprehensive **Register-Transfer Level (RTL) design of a multi-functional Digital Clock and Stopwatch** using Verilog HDL. Deployed on a physical FPGA board, the system provides accurate real-time timekeeping and precise stopwatch measurements, fully displayed on a 4-digit 7-segment display.

Unlike software-based timing solutions, this project is engineered from the ground up at the hardware level, demonstrating core digital logic design principles including clock frequency division, multi-state transition handling (FSM), external input synchronization, and hardware-level display multiplexing.

---

## Project Motivation & Background
While keeping time or measuring intervals is a trivial task for microprocessors using software timers, implementing these functions purely in hardware presents a unique set of engineering challenges. 

The primary motivation for this project was to **master the foundational concepts of sequential logic and digital system design**, which are essential for advanced SoC (System-on-Chip) and ASIC engineering. By building this system without relying on an MCU, this project aims to:
* **Deepen understanding of Clock Domains:** Mastering how to generate and manage precise timebases (1Hz, 100Hz) from a high-frequency system clock.
* **Tackle Real-World Hardware Issues:** Solving physical challenges such as mechanical button bouncing (Debouncing) and asynchronous input metastability.
* **Enhance FSM Design Capabilities:** Designing a robust Finite State Machine to manage complex user interactions and seamless transitions between Clock and Stopwatch modes.
* **Experience the Full Front-End Flow:** Operating through the entire digital design pipeline—from RTL coding and Testbench simulation to physical FPGA synthesis and pin binding.

---

## System Architecture & Core Modules

### 1. Clock Divider & Timebase Generator
* Receives the high-frequency system clock (e.g., 100MHz) and scales it down using internal counters.
* Generates a strict `1Hz` enable tick for the real-time clock (HH:MM:SS) and a `100Hz` (10ms) tick for the stopwatch's precision measurement, ensuring zero clock skew.

### 2. Input Synchronization & Debouncing
* **Debounce Logic:** Eliminates mechanical bouncing noise from tactile push buttons using shift registers and counter-based delay logic, ensuring clean single-pulse inputs.
* **Edge Detection:** Extracts exactly one clock-cycle pulse (Rising Edge) from prolonged user button presses to prevent multiple unintended state transitions.

### 3. Mode Control FSM (Finite State Machine)
* Acts as the brain of the system, seamlessly switching between different operational modes based on user inputs:
  * **`CLOCK_MODE`:** Displays the current time. Includes sub-states for time setting (Hour/Minute adjustment).
  * **`STOPWATCH_MODE`:** Handles Start, Stop, and Clear (Reset) operations accurately down to the hundredth of a second.

### 4. Time Counters & BCD Converters
* Implements cascaded modulo counters (Mod-10, Mod-6, Mod-24) to represent the standard time format (Base-60 for seconds/minutes, Base-24 for hours).
* Dedicated Binary-Coded Decimal (BCD) conversion logic translates raw binary counts into human-readable 7-segment display formats.

### 5. Display Multiplexer (FND Controller)
* Drives a 4-digit 7-segment display using limited FPGA I/O pins.
* Cycles through each digit at a fast refresh rate (e.g., 1kHz) utilizing persistence of vision (POV) to make all 4 digits appear continuously and brightly lit without flickering.

---

## RTL Simulation & Verification
A critical aspect of this project is the rigorous pre-synthesis verification using SystemVerilog/Verilog Testbenches.
* Developed comprehensive testbenches to simulate module behaviors before physical FPGA deployment.
* Verified FSM state transitions, edge detector accuracy, and clock divider outputs using timing waveforms.
* Ensured corner-case stability, such as rapid button presses and simultaneous mode switching, confirming the robustness of the RTL design.

---

## Repository Structure
* `documents/` : Project presentation PDF detailing architectural specifications and FSM state diagrams.
* `source/` : Verilog RTL source codes containing the FSM, clock dividers, BCD counters, and top module.
* `TestBench/` : Simulation testbench files used for RTL verification and timing analysis.
* `constraint/` : FPGA physical pin assignments (Buttons, System Clock, 7-Segment LEDs).
