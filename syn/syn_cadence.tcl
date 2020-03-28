###########################################################################
##  Copyright 2018 Vincent Camus all rights reserved                     ##
##                                                                       ##
##  Project: Carry Cut-Back Adder (CCBA) Source Code                     ##
##  Authors: Vincent Camus (EPFL-ICLAB), vincent.camus@epfl.ch           ##
##  License: BSD-2-Clause                                                ##
##                                                                       ##
##  File: syn_cadence.tcl                                                ##
##  Description: script to synthesize the CCBA wrapper with Cadence      ##
##  Genus, generates:                                                    ##
##  - reports.txt (constraints, timing, area and power reports)          ##
##  - adder32.v   (gate-level netlist of the synthesized CCBA)           ##
##  - adder32.sdf (cell delays for gate-level timing simulation)         ##
##  Usage: genus -legacy_ui -f syn_cadence.tcl                           ##
##                                                                       ##
##  Version: 1.0 (initial version)                                       ##
###########################################################################


############### PARAMETERS ################

# delay constraint
set DELAY     0.5

# library file
set LIB_FILE  ../lib/NangateOpenCellLibrary_PDKv1_3_v2010_12/liberty/NangateOpenCellLibrary_typical.lib

# RTL path
set_attribute hdl_search_path ../rtl

################# LIBRARY #################

set_attribute library $LIB_FILE

############# ANALYZE SOURCE ##############

read_hdl -library work -vhdl ccba_pkg.vhd
read_hdl -library work -vhdl ccba.vhd
read_hdl -library work -vhdl ccba_regular.vhd

# customize your CCBA in this file
read_hdl -library work -vhdl wrapper_ccba_regular_adder32.vhd

############### ELABORATION ###############

set_attribute hdl_parameter_naming_style "" / 

elaborate adder32

check_design
uniquify adder32

######## CCBA PARAMETER EXTRACTION ########

# reporting ccba parameters (but architecture)
redirect -variable CCBA_ATTRIBUTES   {echo [get_attribute hdl_parameters ccba]}

# extracting ccba parameters (but architecture)
regexp -linestop {ADDER_WIDTH ([0-9]+) .*CUT_NUMBER ([0-9]+) .*CUT_POSITIONS [0-9]+'h([0-9a-fA-F]+) .*PROP_WIDTHS [0-9]+'h([0-9a-fA-F]+) .*ADD1_WIDTHS [0-9]+'h([0-9a-fA-F]+) .*SPEC_WIDTHS [0-9]+'h([0-9a-fA-F]+) .*CUT_TYPE 8'h([0-9a-fA-F]+) } \
	$CCBA_ATTRIBUTES MATCHED ADDER_WIDTH CUT_NUMBER CUT_POSITIONS_HEX PROP_WIDTHS_HEX ADD1_WIDTHS_HEX SPEC_WIDTHS_HEX CUT_TYPE_HEX

# reporting ccba architecture
redirect -variable CCBA_ARCHITECTURE {report hierarchy -subdesign ccba}

# extracting ccba architecture
regexp -linestop {arch_(multiplexed|input_induced)} $CCBA_ARCHITECTURE MATCHED ADDER_ARCH

############### CONSTRAINTS ###############

# external timing exception script
source timing_constraints.tcl
echo $TIMING_CONSTRAINTS_REPORT > reports.txt

################# COMPILE #################

ungroup -all -flatten
syn_generic
syn_map
	
################# EXPORTS #################

write_hdl              > adder32.v
write_sdf -version 3.0 > adder32.sdf

################# REPORTS #################

report timing >> reports.txt
report area   >> reports.txt
report power  >> reports.txt
