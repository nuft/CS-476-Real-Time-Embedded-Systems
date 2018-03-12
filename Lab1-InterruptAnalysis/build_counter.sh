#!/bin/bash

mkdir -p vcd
mkdir -p wave

ghdl -a hw/hdl/counter_rtl.vhd
ghdl -a hw/hdl/counter_tb.vhd
ghdl -e counter_tb
ghdl -r counter_tb --vcd=vcd/counter.vcd --wave=wave/counter.ghw --stop-time=100us
