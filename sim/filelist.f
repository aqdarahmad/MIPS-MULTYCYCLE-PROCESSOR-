# From the sim/ directory:
bash run_xrun.sh

# Or manually:
xrun -sv \
    -incdir ../rtl \
    ../rtl/*.sv \
    testbench.sv \
    -timescale 1ns/1ps \
    -access +rwc \
    -log xrun.log \
    -top testbench

# View waveform:
simvision waves.shm &