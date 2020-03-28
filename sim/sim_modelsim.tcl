###########################################################################
##  Copyright 2018 Vincent Camus all rights reserved                     ##
##                                                                       ##
##  Project: Carry Cut-Back Adder (CCBA) Source Code                     ##
##  Authors: Vincent Camus (EPFL-ICLAB), vincent.camus@epfl.ch           ##
##  License: BSD-2-Clause                                                ##
##                                                                       ##
##  File: sim_modelsim.tcl                                               ##
##  Description: script for behavioral testing and characterization      ##
##  of the CCBA wrapper with MentorGraphics Modelsim/Questa, runs the    ##
##  tb_adder32 testbench, shows the error count/assertions on screen     ##
##  and generates a results.txt file with listing of the errors          ##
##  Usage: vsim -do sim_modelsim.tcl (add '-c' for command-line mode)    ##
##                                                                       ##
##  Version: 1.0 (initial version)                                       ##
###########################################################################


################### PARAMETERS ###################

# HDL paths
set RTL_PATH   ../rtl
set BENCH_PATH ../bench

################# COMPILE SOURCE #################

vlib work
vmap work work

vcom -work work $RTL_PATH/ccba_pkg.vhd
vcom -work work $RTL_PATH/ccba.vhd
vcom -work work $RTL_PATH/ccba_regular.vhd

# customize your CCBA in this file
vcom -work work $RTL_PATH/wrapper_ccba_regular_adder32.vhd

vcom -work work $BENCH_PATH/tb_adder32.vhd

################### SIMULATION ###################

# a file named "results.txt" will be created listing the errors
vsim tb_adder32 -t ps 

add wave *
run -all
quit
