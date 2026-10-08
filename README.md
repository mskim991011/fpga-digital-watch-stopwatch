FPGA-based Sensor Interfacing System (HC-SR04 & DHT11)
Project Overview

This project implements a Register-Transfer Level (RTL) hardware design that interfaces two external sensors with a Xilinx Basys 3 FPGA.

Instead of relying on an MCU and pre-written libraries, both sensor protocols are written from scratch in Verilog HDL. The datasheet timing diagrams (pulse-width measurement for the HC-SR04, single-wire bidirectional protocol for the DHT11) are translated directly into Finite State Machines (FSMs). The measured distance, temperature, and humidity are shown on the board's 4-digit 7-segment display.

Project Motivation & Background

Sensors like the HC-SR04 and DHT11 are usually read with an Arduino library, which hides the actual signal timing.

The goal of this project was to handle that timing directly in hardware:

Practical digital design: Build working communication interfaces, not just logic gates.
Microsecond-level timing: Generate and measure pulses with a dedicated timebase instead of software delays.
Fault handling in hardware: Make sure the FSMs never hang when a sensor stops responding.
Foundation for SoC work: Write sensor controllers as reusable hardware blocks.
System Architecture & Data Flow
Timebase generators
tick_gen_1us: 1 MHz enable tick from the 100 MHz system clock (HC-SR04 timing).
tick_gen_10us: 100 kHz enable tick (DHT11 timing).
Sensor control FSMs
Independent FSMs implement the HC-SR04 and DHT11 protocols, extract the raw data, perform the arithmetic (division for distance, byte sum for checksum), and output the final values.
Display controller (fnd_contr)
Converts the binary values to BCD and multiplexes them onto the 7-segment display.
Button input (bt_debounce)
Debounces the push buttons and generates a single-cycle pulse with an edge detector.
Detailed Module Specifications
1. HC-SR04 Ultrasonic Distance Controller (sr04_ctrl)
Trigger pulse: Drives a trigger pulse of about 12 µs, satisfying the sensor's minimum of 10 µs.
4-state FSM: IDLE → TRIG → WAIT → CALC.
WAIT: waits for the echo signal to rise.
CALC: counts the echo high time in 1 µs units.
Distance calculation: Distance (cm) = echo high time (µs) / 58, computed in hardware when the echo signal falls.
Two timeouts (hang prevention):
30 ms in WAIT: if the echo never rises (sensor disconnected or no response), the FSM returns to IDLE and outputs 0.
25 ms in CALC: the longest valid echo is about 23.2 ms (4 m × 58 µs/cm). If the echo stays high longer than 25 ms, the measurement is discarded and the FSM returns to IDLE.
Measurement period: A new measurement starts automatically every 100 ms, which satisfies the datasheet recommendation of a measurement cycle over 60 ms.
2. DHT11 Temperature & Humidity Controller (dht11_controller)
Tri-state control: Controls the single inout data line. Drives it LOW for 19 ms (start signal, datasheet minimum 18 ms), releases it, and waits about 30 µs before switching to input mode.
8-state FSM: IDLE → START → WAIT → SYNC_L → SYNC_H → DATA_SYNC → DATA_C → STOP.
Bit decoding: Measures the high time of each bit with the 10 µs tick. High time of 50 µs or more is decoded as 1, otherwise 0. 40 bits are shifted in.
Checksum verification: Adds the four data bytes (humidity integer/decimal, temperature integer/decimal) and compares the 8-bit result with the checksum byte. dht11_valid is asserted only when they match.
Timeout: If a transaction does not finish within 1 s (100,000 × 10 µs), the FSM releases the line and returns to IDLE.
Trigger: A measurement starts on a button press, or automatically when the idle counter expires (6,000,000 × 10 µs = about 60 s).
Engineering Challenges & Solutions
Challenge: The FSM froze when a sensor was disconnected or the echo pulse was lost.
Solution: Calculated the longest valid duration for each step and added counter-based timeouts (HC-SR04: 30 ms wait / 25 ms measurement, DHT11: 1 s). When a limit is exceeded the FSM resets to IDLE, so the system recovers on the next cycle without a manual reset.
Challenge: Button bouncing caused multiple unintended inputs.
Solution: Added a debounce circuit and an edge detector so that each press produces exactly one pulse.
Known Limitations & Future Work
The echo and dhtio inputs are sampled directly by the FSMs without a dedicated synchronizer. Adding a 2-stage flip-flop synchronizer on these asynchronous inputs would reduce the risk of metastability.
The distance division uses the / operator, which synthesizes a combinational divider. A sequential or multiply-shift approximation could reduce logic depth.
No testbench is included in this repository; verification was done on the Basys 3 board.
Development Environment
Target Hardware: Xilinx Basys 3 (Artix-7)
Peripherals: HC-SR04 ultrasonic sensor, DHT11 temperature & humidity sensor
Language: Verilog HDL
EDA Tool: Xilinx Vivado (synthesis, implementation, bitstream generation)
Key Focus Areas: RTL design, FSM, microsecond timing, timeout-based fault recovery, hardware arithmetic
