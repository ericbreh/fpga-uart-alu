# FPGA UART ALU

An FPGA-based Arithmetic Logic Unit implementation with UART communication interface. This project enables performing arithmetic operations by sending commands over UART from a computer to an FPGA board.

## Features

* Addition of multiple 32-bit integers
* Multiplication of multiple 32-bit signed integers
* Division of two 32-bit signed integers
* Echo functionality for testing communication

## Dependencies

This project uses the following third-party IP cores:

* [alexforencich/verilog-uart](https://github.com/alexforencich/verilog-uart) - UART communication modules
* [basejump_stl](https://github.com/bespoke-silicon-group/basejump_stl) - Integer multiplication and division modules
  * bsg_imul_iterative.sv for multiplication
  * bsg_idiv_iterative.sv for division
