---------------------------------------------------------------------------
--  Copyright 2018 Vincent Camus all rights reserved                     --
--                                                                       --
--  Project: Carry Cut-Back Adder (CCBA) Source Code                     --
--  Authors: Vincent Camus (EPFL-ICLAB), vincent.camus@epfl.ch           --
--  License: BSD-2-Clause                                                --
--                                                                       --
--  File: ccba_regular.vhd                                               --
--  Description: wrapper to instantiate a regular CCBA entity with       --
--  uniformly-sized blocks and equally spaced cuts                       --
--                                                                       --
--  Version: 1.0 (initial version)                                       --
--                                                                       --
--  Notes: generating the array of bitwidths and bit spacing for the     --
--  normal (fully-custom) CCBA entity                                    --
---------------------------------------------------------------------------


------------------------------------------------------------------- packages and libraries

library ieee, work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ccba_pkg.all; -- unconstrained natural_array type definition


------------------------------------------------------------------- ccba_regular entity declaration

entity ccba_regular is
	generic(
		ADDER_ARCH   : string;      -- architecture ["multiplexed","input_induced"]
		ADDER_WIDTH  : natural;     -- adder bitwidth
		CUT_NUMBER   : natural;     -- number of cuts
		CUT_SPACING  : natural;     -- bit spacing between two cuts (multiple cuts only)
		CUT_1ST_POS  : natural;     -- index of the first cut (carry-in/input of the stage)
		PROP_WIDTH   : natural;     -- width of the PROP
		ADD1_WIDTH   : natural;     -- distance between the cuts and the PROP
		SPEC_WIDTH   : natural;     -- width of the SPEC block (multiplexed architecture only)
		CUT_TYPE     : character ); -- guess/input-override type ['0','1','a','b']
	port(
		a   : in  std_logic_vector (ADDER_WIDTH-1 downto 0);
		b   : in  std_logic_vector (ADDER_WIDTH-1 downto 0);
		cin : in  std_logic;
		s   : out std_logic_vector (ADDER_WIDTH downto 0) );
end entity ccba_regular;


------------------------------------------------------------------- ccba_regular architecture rtl

architecture rtl of ccba_regular is

	-- cut position generator
	function init_cut_positions return natural_array is
		variable positions : natural_array(0 to CUT_NUMBER-1);
	begin
		for i in 0 to CUT_NUMBER-1 loop
			positions(i) := CUT_1ST_POS + i*(CUT_SPACING-1);
		end loop;
		return positions;
	end function;
	
	-- getting ccba natural_array parameters from ccba_regular natural values
	constant CUT_POSITIONS : natural_array(0 to CUT_NUMBER-1) := init_cut_positions;
	constant PROP_WIDTHS   : natural_array(0 to CUT_NUMBER-1) := (others => PROP_WIDTH);
	constant ADD1_WIDTHS   : natural_array(0 to CUT_NUMBER-1) := (others => ADD1_WIDTH);
	constant SPEC_WIDTHS   : natural_array(0 to CUT_NUMBER-1) := (others => SPEC_WIDTH);
	
	-- component declaration
	component ccba is
		generic (
			ADDER_ARCH    : string;
			ADDER_WIDTH   : natural;
			CUT_NUMBER    : natural;
			CUT_POSITIONS : natural_array;
			PROP_WIDTHS   : natural_array;
			ADD1_WIDTHS   : natural_array;
			SPEC_WIDTHS   : natural_array;
			CUT_TYPE      : character );
		port (
			a   : in  std_logic_vector (ADDER_WIDTH-1 downto 0);
			b   : in  std_logic_vector (ADDER_WIDTH-1 downto 0);
			cin : in  std_logic;
			s   : out std_logic_vector (ADDER_WIDTH downto 0) );
	end component ccba;
	
begin
	
	-- instantiation of ccba
	inst_ccba: ccba
	generic map (
		ADDER_ARCH    => ADDER_ARCH,
		ADDER_WIDTH   => ADDER_WIDTH,
		CUT_NUMBER    => CUT_NUMBER,
		CUT_POSITIONS => CUT_POSITIONS,
		PROP_WIDTHS   => PROP_WIDTHS,
		ADD1_WIDTHS   => ADD1_WIDTHS,
		SPEC_WIDTHS   => SPEC_WIDTHS,
		CUT_TYPE      => CUT_TYPE )
	port map (
		a   => a,
		b   => b,
		cin => cin,
		s   => s );
	
end architecture rtl;