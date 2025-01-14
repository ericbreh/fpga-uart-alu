`timescale 1ns / 1ps

package config_pkg;

  // define structs and enums needed for design
  typedef enum logic [2:0] {
    IDLE,
    RX_OPCODE,
    RX_RESERVED,
    RX_LENGTH_LSB,
    RX_LENGTH_MSB,
    ECHO,
    ADD,
    TRANSMIT
  } state_t;

endpackage
