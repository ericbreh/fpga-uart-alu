rtl/config_pkg.sv

-DNO_ICE40_DEFAULT_ASSIGNMENTS
${YOSYS_DATDIR}/ice40/cells_sim.v

synth/icestorm_icebreaker/build/synth.v
synth/icestorm_icebreaker/alu_runner.sv

-I${UART_DIR}/rtl
${UART_DIR}/rtl/uart_rx.v
${UART_DIR}/rtl/uart_tx.v
${UART_DIR}/rtl/uart.v

-I${BASEJUMP_STL_DIR}/bsg_misc
${BASEJUMP_STL_DIR}/bsg_misc/bsg_imul_iterative.sv
${BASEJUMP_STL_DIR}/bsg_misc/bsg_idiv_iterative.sv