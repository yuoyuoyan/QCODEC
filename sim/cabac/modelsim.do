vlib work
vlog -f ../rtl/cmn/cmn_rtl.f -f ../rtl/cabac/qdec_cabac_rtl.f +incdir+../tb/cmn/ ../tb/tb_cabac.sv
vsim work.tb_cabac -voptargs=+acc +notimingchecks
log -depth 7 /tb_cabac/*
do wave.do
run 10us