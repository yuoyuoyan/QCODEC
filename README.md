# QCODEC
Planning to build an FPGA-based HEVC codec RTL. Currently planning to implement on Zybo board, decoder first

Referring to the HM HEVC codec, modified C code to dump required testing data. Modified source folder can be found inside the repo, but need to clone the official git branch to run:
https://vcgit.hhi.fraunhofer.de/jvet/HM.git

Options to run sim on QCODEC: ModelSim/QuestaSim and Icarus Verilog/GTKWave. Pls search online how to install them. The scripts to run them are provided inside sim folder