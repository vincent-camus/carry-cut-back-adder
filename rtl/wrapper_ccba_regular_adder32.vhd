---------------------------------------------------------------------------
--  Copyright 2018 Vincent Camus all rights reserved                     --
--                                                                       --
--  Project: Carry Cut-Back Adder (CCBA) Source Code                     --
--  Authors: Vincent Camus (EPFL-ICLAB), vincent.camus@epfl.ch           --
--  License: BSD-2-Clause                                                --
--                                                                       --
--  File: wrapper_ccba_regular_adder32.vhd                               --
--  Description: wrapper of ccba_regular to adder32, customize your      --
--  CCBA architecture and parameters in this file                        --
--                                                                       --
--  Version: 1.0 (initial version)                                       --
---------------------------------------------------------------------------


------------------------------------------------------------------- packages and libraries

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


------------------------------------------------------------------- adder32 entity declaration

entity adder32 is
	port (
		a   : in  std_logic_vector (31 downto 0);
		b   : in  std_logic_vector (31 downto 0);
		cin : in  std_logic;
		s   : out std_logic_vector (32 downto 0) );
end entity adder32;


------------------------------------------------------------------- adder32 architecture rtl

architecture rtl of adder32 is
	
	-- *** CUSTOMIZE THE CCBA ARCHITECTURE HERE ***
	constant ADDER_ARCH  : string    := "multiplexed"; -- architecture ["multiplexed","input_induced"]
	
	-- *** CUSTOMIZE CUT PARAMETERS HERE ***
	constant CUT_NUMBER  : natural   := 2;   -- number of cuts
	constant CUT_SPACING : natural   := 8;   -- bit spacing between two cuts (multiple cuts only)
	constant CUT_1ST_POS : natural   := 3;   -- index of the first cut (carry-in/input of the stage)
	constant PROP_WIDTH  : natural   := 1;   -- width of the PROP
	constant ADD1_WIDTH  : natural   := 6;   -- distance between the cuts and the PROP
	constant SPEC_WIDTH  : natural   := 0;   -- width of the SPEC block (multiplexed architecture only)
	constant CUT_TYPE    : character := '1'; -- guess/input-override type ['0','1','a','b']

	-- adder bitwidth
	constant ADDER_WIDTH : natural   := 32;  -- 32 bits for simulation with the provided testbench

	-- ccba_regular component
	component ccba_regular is
	generic (
		ADDER_ARCH  : string;
		ADDER_WIDTH : natural;
		CUT_NUMBER  : natural;
		CUT_SPACING : natural;
		CUT_1ST_POS : natural;
		PROP_WIDTH  : natural;
		ADD1_WIDTH  : natural;
		SPEC_WIDTH  : natural;
		CUT_TYPE    : character );
	port (
		a   : in  std_logic_vector (ADDER_WIDTH-1 downto 0);
		b   : in  std_logic_vector (ADDER_WIDTH-1 downto 0);
		cin : in  std_logic;
		s   : out std_logic_vector (ADDER_WIDTH downto 0) );
	end component ccba_regular;

begin

	-- ccba_regular instantiation 
	inst_ccba_regular: ccba_regular
	generic map (
		ADDER_ARCH  => ADDER_ARCH,
		ADDER_WIDTH => ADDER_WIDTH,
		CUT_NUMBER  => CUT_NUMBER,
		CUT_SPACING => CUT_SPACING,
		CUT_1ST_POS => CUT_1ST_POS,
		PROP_WIDTH  => PROP_WIDTH,
		ADD1_WIDTH  => ADD1_WIDTH,
		SPEC_WIDTH  => SPEC_WIDTH,
		CUT_TYPE    => CUT_TYPE )
	port map (
		a   => a,
		b   => b,
		cin => cin,
		s   => s );

end architecture rtl;
