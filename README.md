SPI Master with APB Interface

This was a small RTL project I built while learning SystemVerilog and digital design.

The project started as a basic SPI master and I later added:

1) TX/RX FIFOs
2) APB interface
3) configurable clock divider
4) self-checking testbench

The SPI transfer is controlled through APB writes, and received data can be read back through APB reads.

Currently implemented:

1) SPI Mode 0
2) FIFO buffering
3) APB-controlled transfers
4) parameterized data width

The design was simulated using Icarus Verilog and GTKWave.
Some things I still want to improve:

1) support for all SPI modes(I tried it but timing issues arrived)
2) better APB status handling
3) cleaner verification structure

Waveform
<img width="1992" height="1240" alt="image" src="https://github.com/user-attachments/assets/6d550552-30a2-45dd-936e-f50628597587" />
