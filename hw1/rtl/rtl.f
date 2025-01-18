// UART modules
-I${UART_DIR}/rtl
${UART_DIR}/rtl/uart_rx.v
${UART_DIR}/rtl/uart_tx.v
${UART_DIR}/rtl/uart.v

// BSG STL basic modules
-I${BASEJUMP_STL_DIR}/bsg_misc
${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_en.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_mux_one_hot.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_adder_cin.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_counter_clear_up.sv

// BSG STL arithmetic modules
${BASEJUMP_STL_DIR}/bsg_misc/bsg_imul_iterative.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_idiv_iterative.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_idiv_iterative_controller.sv

// Project RTL
rtl/config_pkg.sv
rtl/alu.sv