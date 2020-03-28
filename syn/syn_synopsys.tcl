###########################################################################
##  Copyright 2018 Vincent Camus all rights reserved                     ##
##                                                                       ##
##  Project: Carry Cut-Back Adder (CCBA) Source Code                     ##
##  Authors: Vincent Camus (EPFL-ICLAB), vincent.camus@epfl.ch           ##
##  License: BSD-2-Clause                                                ##
##                                                                       ##
##  File: syn_synopsys.tcl                                               ##
##  Description: script to synthesize the CCBA wrapper with Synopsys     ##
##  Design Compiler, generates:                                          ##
##  - reports.txt (constraints, timing, area and power reports)          ##
##  - adder32.v   (gate-level netlist of the synthesized CCBA)           ##
##  - adder32.sdf (cell delays for gate-level timing simulation)         ##
##  Usage: dc_shell -f syn_synopsys.tcl                                  ##
##                                                                       ##
##  Version: 1.0 (initial version)                                       ##
###########################################################################


############### PARAMETERS ################

# delay constraint
set DELAY     0.5

# library file
set DB_FILE   ../lib/NangateOpenCellLibrary_PDKv1_3_v2010_12/liberty/NangateOpenCellLibrary_typical.db

# RTL path
set RTL_PATH  ../rtl

################# LIBRARY #################

define_design_lib work -path work

set target_library $DB_FILE
set link_library   $DB_FILE

############# ANALYZE SOURCE ##############

analyze -format vhdl -work work $RTL_PATH/ccba_pkg.vhd
analyze -format vhdl -work work $RTL_PATH/ccba.vhd
analyze -format vhdl -work work $RTL_PATH/ccba_regular.vhd

# customize your CCBA in this file
analyze -format vhdl -work work $RTL_PATH/wrapper_ccba_regular_adder32.vhd

############### ELABORATION ###############

elaborate adder32

check_design
link
uniquify

######## CCBA PARAMETER EXTRACTION ########

# reporting ccba parameters
redirect -variable CCBA_ATTRIBUTES {report_attribute -nosplit -hierarchy -design}

# extracting ccba parameters (used for timing exception script)
regexp {ccba_[a-zA-Z0-9_]+ design hdl_parameters ADDER_ARCH => \"([a-zA-Z0-9_]+)\", ADDER_WIDTH => ([0-9]+), CUT_NUMBER => ([0-9a-fA-F]+), CUT_POSITIONS => [0-9]+'h([0-9a-fA-F]+), PROP_WIDTHS => [0-9]+'h([0-9a-fA-F]+), ADD1_WIDTHS => [0-9]+'h([0-9a-fA-F]+), SPEC_WIDTHS => [0-9]+'h([0-9a-fA-F]+), CUT_TYPE => 8'h([0-9a-fA-F]+)} \
	$CCBA_ATTRIBUTES MATCHED ADDER_ARCH ADDER_WIDTH CUT_NUMBER CUT_POSITIONS_HEX PROP_WIDTHS_HEX ADD1_WIDTHS_HEX SPEC_WIDTHS_HEX CUT_TYPE_HEX

############### CONSTRAINTS ###############

# external timing exception script
source timing_constraints.tcl
echo $TIMING_CONSTRAINTS_REPORT > reports.txt

set_max_area 0

################# COMPILE #################

compile_ultra

################# EXPORTS #################

change_names -rules verilog -hier
define_name_rules fixbackslashes -allowed "A-Za-z0-9_" -first_restricted "\\" -remove_chars
change_names -rule fixbackslashes -h

write -f verilog -hierarchy -output adder32.v
write_sdf -version 3.0              adder32.sdf

################# REPORTS #################

report_timing -nosplit >> reports.txt
report_area   -nosplit >> reports.txt
report_power  -nosplit >> reports.txt
