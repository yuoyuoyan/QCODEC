vlib work
vlog -f ../rtl/cabac/qdec_cabac_rtl.f -f ../rtl/cmn/cmn_rtl.f ../tb/tb_cabac.sv
vsim work.tb_microphone_recorder -voptargs=+acc +notimingchecks
log -depth 7 /tb_cabac/*
do wave.do
run 10us