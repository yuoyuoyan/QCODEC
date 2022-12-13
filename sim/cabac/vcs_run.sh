vlogan -full64 -work xil_defaultlib -sverilog -kdb -debug_access+r -timescale=1ns/1ps -f cabac.tb.f
vcs -full64 -sverilog -kdb -debug_access+r -debug_access -debug_region=cell+encrypt -P $NOVAS_HOME/share/PLI/VCS/linux64/novas.tab -timescale=1ns/1ps +vcs+lic+wait -lca -o mb.simv
./mb.simv
