###########################################################################
##  Copyright 2018 Vincent Camus all rights reserved                     ##
##                                                                       ##
##  Project: Carry Cut-Back Adder (CCBA) Source Code                     ##
##  Authors: Vincent Camus (EPFL-ICLAB), vincent.camus@epfl.ch           ##
##  License: BSD-3-Clause-Clear                                          ##
##                                                                       ##
##  File: timing_constraints.tcl                                         ##
##  Description: script to set-up delay constraints of the CCBA wrapper  ##
##                                                                       ##
##  Version: 1.0 (initial version)                                       ##
##                                                                       ##
##  Notes: called in the synthesis script                                ##
###########################################################################

# getting guess/input-override type
set CUT_TYPE [binary format H* $CUT_TYPE_HEX]

# checking for ADDER_ARCH error (optional)
if {$ADDER_ARCH ne "multiplexed" && $ADDER_ARCH ne "input_induced"} {
	echo "ERROR: unknown ADDER_ARCH $ADDER_ARCH"
	exit 1
}

# checking for CUT_TYPE error in multiplexed architectures (optional)
if {$ADDER_ARCH eq "multiplexed" && $CUT_NUMBER !=  0 && $CUT_TYPE ne "0" && $CUT_TYPE ne "1"
&& $CUT_TYPE ne "a" && $CUT_TYPE ne "A" && $CUT_TYPE ne "b" && $CUT_TYPE ne "B"} {
	echo "ERROR: unknown CUT_TYPE $CUT_TYPE"
	exit 1
}

# reporting
set TIMING_CONSTRAINTS_REPORT "Extracted design attributes:
ADDER_ARCH    $ADDER_ARCH
ADDER_WIDTH   $ADDER_WIDTH
CUT_NUMBER    $CUT_NUMBER
CUT_TYPE      '$CUT_TYPE'\n
Extracted cut ranges:\n"

# extracting ccba array values
array set CUT_POSITIONS [list 0 0]
array set PROP_WIDTHS   [list 0 0]
array set ADD1_WIDTHS   [list 0 0]
array set SPEC_WIDTHS   [list 0 0]
for {set CUT 1} {$CUT <= $CUT_NUMBER} {incr CUT} {
	array set CUT_POSITIONS [list $CUT [scan [string range $CUT_POSITIONS_HEX [expr {2*($CUT-1)}] [expr {2*$CUT-1}]] %x]]
	array set PROP_WIDTHS   [list $CUT [scan [string range $PROP_WIDTHS_HEX   [expr {2*($CUT-1)}] [expr {2*$CUT-1}]] %x]]
	array set ADD1_WIDTHS   [list $CUT [scan [string range $ADD1_WIDTHS_HEX   [expr {2*($CUT-1)}] [expr {2*$CUT-1}]] %x]]
	array set SPEC_WIDTHS   [list $CUT [scan [string range $SPEC_WIDTHS_HEX   [expr {2*($CUT-1)}] [expr {2*$CUT-1}]] %x]]
	append TIMING_CONSTRAINTS_REPORT \
		"CUT $CUT: POS $CUT_POSITIONS($CUT), PROP $PROP_WIDTHS($CUT), ADD1 $ADD1_WIDTHS($CUT), SPEC $SPEC_WIDTHS($CUT)\n"
}

# reporting
append TIMING_CONSTRAINTS_REPORT "\nApplied delay ranges:\n"

# initialize arrays of port collections
array unset I_PORTS
array unset O_PORTS

# loop on the different port ranges
for {set CUT 0} {$CUT <= $CUT_NUMBER} {incr CUT} {
	
	# reporting
	append TIMING_CONSTRAINTS_REPORT "CUT $CUT: "
	
	# start index of the current port range
	if {$ADDER_ARCH eq "multiplexed"} {
		set START [expr {$CUT_POSITIONS($CUT)-$SPEC_WIDTHS($CUT)}]
	} else {
		# ignoring SPEC parameter for input-induced CCBA (optional)
		set START $CUT_POSITIONS($CUT)
	}
	
	# stop index of the current port range
	if {$CUT != $CUT_NUMBER} {
		set STOP [expr {$CUT_POSITIONS([expr $CUT+1])+$PROP_WIDTHS([expr $CUT+1])+$ADD1_WIDTHS([expr $CUT+1])}]
	} else {
		# exception for last port range
		set STOP $ADDER_WIDTH
	}
	
	# reporting
	echo "Processing port range CUT=$CUT / \[$START-$STOP\]"
	
	# exception for carry-in of first CUT port range 
	if {$CUT == 0} {
		append_to_collection I_PORTS($CUT) [get_ports {cin}] -unique
		append TIMING_CONSTRAINTS_REPORT "cin+"
	}
	
	# exception for preceding port when variable guess in multiplexed architectures
	if {$CUT != 0 && $ADDER_ARCH eq "multiplexed"} {
		set GUESS_INDEX [expr {$START-1}]
		if {$CUT_TYPE eq "a" || $CUT_TYPE eq "A"} {
			append_to_collection I_PORTS($CUT) [get_ports a[$GUESS_INDEX]]
			append TIMING_CONSTRAINTS_REPORT "a\[$GUESS_INDEX\]+"
		}
		if {$CUT_TYPE eq "b" || $CUT_TYPE eq "B"} {
			append_to_collection I_PORTS($CUT) [get_ports b[$GUESS_INDEX]]
			append TIMING_CONSTRAINTS_REPORT "b\[$GUESS_INDEX\]+"
		}
	}
	
	# adding regular port range
	for {set K $START} {$K <= $STOP} {incr K} {
		append_to_collection O_PORTS($CUT) [get_ports s[$K]]
		if {$K != $ADDER_WIDTH} {
			append_to_collection I_PORTS($CUT) [get_ports a[$K]]
			append_to_collection I_PORTS($CUT) [get_ports b[$K]]
		}
	}
	append TIMING_CONSTRAINTS_REPORT "\[$START-$STOP\]\n"
	
	# sorting port collections (optional)
	sort_collection $I_PORTS($CUT) {full_name}
	sort_collection $O_PORTS($CUT) {full_name}
	
	# applying delay constraint
	set_max_delay $DELAY -from [get_ports $I_PORTS($CUT)] -to [get_ports $O_PORTS($CUT)]
}

# reporting
append TIMING_CONSTRAINTS_REPORT "\nDelay constraints script done\n\n"
