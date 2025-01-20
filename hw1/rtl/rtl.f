// UART
-I${UART_DIR}/rtl
${UART_DIR}/rtl/uart_rx.v
${UART_DIR}/rtl/uart_tx.v
${UART_DIR}/rtl/uart.v

// BSG
-I${BASEJUMP_STL_DIR}/bsg_misc
${BASEJUMP_STL_DIR}/bsg_misc/bsg_imul_iterative.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_idiv_iterative.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_idiv_iterative_controller.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_dff_en.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_mux_one_hot.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_adder_cin.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_counter_clear_up.sv


// Project RTL
rtl/config_pkg.sv
rtl/alu.sv