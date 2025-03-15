# Verilog Project to Silicon: CSE 293

## Introduction

* Instructor: [Ethan Sifferman](https://github.com/sifferman)
* Objectives
  * Learn to manage large Verilog projects
  * Learn debug and verification strategies
  * Practice writing build scripts using Makefile and TCL
  * Exercise version control and collaboration with Git/GitHub
  * Practice using a multitude of open-source tools and resources such as Verilator, Yosys, zachjs/sv2v, OpenLane, SKY130, BaseJump STL, and more

## Contents

* [FPGA UART ALU](./fpga-uart-alu/)
* [Final Project](https://github.com/nunibye/cse293-final-project)



# FPGA UART ALU

An FPGA-based Arithmetic Logic Unit (ALU) implementation with UART communication interface. This project enables performing arithmetic operations by sending commands over UART from a computer to an FPGA board.

This project was developed as part of [CSE 293: Verilog Project to Silicon](https://github.com/sifferman/ucsc-w25-cse293/tree/main/hw1).

## Highlights

* [Python ALU Interface](python/alu_interface.py)
* [ALU RTL](rtl/alu.sv)
* [Report](report/report.pdf)

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
