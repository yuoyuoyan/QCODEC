# QCODEC
Planning to build an FPGA-based HEVC codec RTL. Currently planning to implement on Zybo board, decoder first

Referring to the HM HEVC codec, modified C code to dump required testing data. Modified source folder can be found inside the repo, but need to clone the official git branch to run:
https://vcgit.hhi.fraunhofer.de/jvet/HM.git

```
git clone https://vcgit.hhi.fraunhofer.de/jvet/HM.git
git clone git@github.com:yuoyuoyan/QCODEC.git
cd HM
cp -rf ../QCODEC/source .
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j
```

Options to run sim on QCODEC: ModelSim/QuestaSim, vcs and Icarus Verilog/GTKWave. Pls search online how to install them. The scripts to run them are provided inside sim folder