`timescale 1ns / 1ps

package config_pkg;

  typedef enum logic [3:0] {
    IDLE,
    RX_OPCODE,
    RX_RESERVED,
    RX_LENGTH_LSB,
    RX_LENGTH_MSB,
    ECHO,
    ADD,
    MUL,
    MUL_WAIT,
    TRANSMIT
  } state_t;

  parameter logic [7:0] OPCODE_ECHO = 8'hEC;
  parameter logic [7:0] OPCODE_ADD = 8'hAD;
  parameter logic [7:0] OPCODE_MUL = 8'h88;
  parameter logic [7:0] OPCODE_DIV = 8'hD1;

endpackage
