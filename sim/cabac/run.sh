rm cabac_waveform.vcd
iverilog -o cabac.vvp -g2012 -DIVERILOG \
-I ../../rtl/cmn \
../../rtl/cmn/axi_pkg.sv \
../../rtl/cmn/basic_ram.sv \
../../rtl/cmn/basic_fifo.sv \
../../rtl/cabac/qdec_cabac_package.sv \
../../rtl/cabac/qdec_cabac_register.sv \
../../rtl/cabac/qdec_dqp_fsm.sv \
../../rtl/cabac/qdec_cqp_fsm.sv \
../../rtl/cabac/qdec_res_fsm.sv \
../../rtl/cabac/qdec_mvd_fsm.sv \
../../rtl/cabac/qdec_tu_fsm.sv \
../../rtl/cabac/qdec_pu_fsm.sv \
../../rtl/cabac/qdec_trafo_fsm.sv \
../../rtl/cabac/qdec_cu_fsm.sv \
../../rtl/cabac/qdec_cqt_fsm.sv \
../../rtl/cabac/qdec_sao_fsm.sv \
../../rtl/cabac/qdec_ctx_init.sv \
../../rtl/cabac/qdec_ctx_fsm.sv \
../../rtl/cabac/qdec_Arith_decoder.sv \
../../rtl/cabac/qdec_line_buffer.sv \
../../rtl/cabac/qdec_ctx_mem.sv \
../../rtl/cabac/qdec_cabac.sv \
../../tb/tb_cabac.sv
vvp cabac.vvp