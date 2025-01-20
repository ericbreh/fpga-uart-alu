`timescale 1ns / 1ps

package config_pkg;

  typedef enum logic [4:0] {
    OPCODE,
    RESERVED,
    LENGTH_LSB,
    LENGTH_MSB,
    FIRST_NUMBER,
    RX_NUMBER,
    ADD,
    MUL,
    DIV,
    ECHO,
    TRANSMIT

  } state_t;

  parameter logic [7:0] OPCODE_ECHO = 8'hEC;
  parameter logic [7:0] OPCODE_ADD = 8'hAD;
  parameter logic [7:0] OPCODE_MUL = 8'h88;
  parameter logic [7:0] OPCODE_DIV = 8'hD1;

endpackage
