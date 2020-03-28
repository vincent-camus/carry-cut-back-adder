---------------------------------------------------------------------------
--  Copyright 2018 Vincent Camus all rights reserved                     --
--                                                                       --
--  Project: Carry Cut-Back Adder (CCBA) Source Code                     --
--  Authors: Vincent Camus (EPFL-ICLAB), vincent.camus@epfl.ch           --
--  License: BSD-2-Clause                                                --
--                                                                       --
--  File: tb_adder32.vhd                                                 --
--  Description: adder32 testbench                                       --
--                                                                       --
--  Version: 1.0 (initial version)                                       --
---------------------------------------------------------------------------


------------------------------------------------------------------- packages and libraries

library ieee, std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;


------------------------------------------------------------------- tb_ccba entity declaration

entity tb_adder32 is
	generic (
		DELAY        : time    := 0.5 ns;
		STIMULI_FILE : string  := "../bench/stimuli.txt";
		RESULTS_FILE : string  := "results.txt";
		STOP_AT      : natural := 10000; -- use to stop before the end of the stimuli file
		ADDER_WIDTH  : natural := 32 );  -- 32 only with the provided stimuli file
end tb_adder32;


------------------------------------------------------------------- tb_ccba architecture bench

architecture bench of tb_adder32 is
	
	-- uut component declaration
	component adder32 is
		port (
			a   : in  std_logic_vector (ADDER_WIDTH-1 downto 0);
			b   : in  std_logic_vector (ADDER_WIDTH-1 downto 0);
			cin : in  std_logic;
			s   : out std_logic_vector (ADDER_WIDTH downto 0) );
	end component adder32;
	
	-- signals
	signal a        : std_logic_vector (ADDER_WIDTH-1 downto 0);
	signal b        : std_logic_vector (ADDER_WIDTH-1 downto 0);
	signal cin      : std_logic;
	signal s_approx : std_logic_vector (ADDER_WIDTH downto 0);
	signal s_exact  : std_logic_vector (ADDER_WIDTH downto 0);
	
begin

	-- uut instantiation
	uut: adder32
	port map (
		a   => a,
		b   => b,
		cin => cin,
		s   => s_approx );
	
	-- reference exact adder
	s_exact <= std_logic_vector( unsigned('0' & a) + unsigned('0' & b) + (cin & "") );
	
	process
		
		-- file pointers
		file fp_stimuli : text;
		file fp_results : text;

		-- counters
		variable stimuli_counter : natural := 0;
		variable error_counter   : natural := 0;
		
		-- read/write variables
		variable v_results : line;
		variable v_stimuli : line;
		variable v_stim    : integer;
		variable v_a       : std_logic_vector (ADDER_WIDTH-1 downto 0);
		variable v_b       : std_logic_vector (ADDER_WIDTH-1 downto 0);
		variable v_cin     : std_logic;
		variable v_trash   : character; -- space characters to trash
		
	begin
	
		-- opening files
		file_open(fp_results, RESULTS_FILE, write_mode);
		file_open(fp_stimuli, STIMULI_FILE, read_mode);
		
		-- writing first line
		write(v_results, string'("STIM_NB"), left, 11);
		write(v_results, string'("EXACT"),   left, ADDER_WIDTH+3);
		write(v_results, string'("APPROX"),  left, ADDER_WIDTH+3);
		write(v_results, string'("ERROR_PATTERN"));
		writeline(fp_results,v_results);
		
		-- initial signals
		a   <= (others => '0');
		b   <= (others => '0');
		cin <= '0';
		wait for DELAY;
		
		-- main bench
		while (not endfile(fp_stimuli) and (stimuli_counter < STOP_AT)) loop

			-- incrementing stimuli counter
			stimuli_counter := stimuli_counter+1;
			
			-- reading stimulus
			readline (fp_stimuli,v_stimuli);
			read(v_stimuli, v_stim);  -- line/stimuli number
			read(v_stimuli, v_trash); -- ignoring space
			read(v_stimuli, v_a);
			read(v_stimuli, v_trash); -- ignoring space
			read(v_stimuli, v_b);
			read(v_stimuli, v_trash); -- ignoring space
			read(v_stimuli, v_cin);
			
			-- applying stimulus
			wait for DELAY;
			a   <= v_a;
			b   <= v_b;
			cin <= v_cin;
			wait for DELAY;
			
			-- assert error
			if (s_approx /= s_exact) then
			
				-- asserting (for waveforms of EDA software)
				assert s_approx = s_exact;
				
				-- incrementing error counter
				error_counter := error_counter+1;
				
				-- writing stimuli number, expected sum and approx sum
				write(v_results, v_stim,   left, 11);
				write(v_results, s_exact,  left, ADDER_WIDTH+3);
				write(v_results, s_approx, left, ADDER_WIDTH+3);
				
				-- writing erroneous bit pattern
				for i in s_approx'range loop
					if (s_approx(i) = s_exact(i)) then
						write(v_results, string'("."), left, 1); -- appending "." if identical
					else
						write(v_results, s_approx(i),  left, 1); -- appending approx bit if different
					end if;
				end loop;
				
				-- writing result file
				writeline(fp_results, v_results);
				
			end if;
			
		end loop;

		-- closing files
		file_close(fp_stimuli);
		file_close(fp_results);
		
		-- reporting
		report "Main bench finished. "
			& integer'image(stimuli_counter) & " stimuli applied with "
			& integer'image(error_counter)   & " errors.";

		-- finish
		wait;
		
	end process;

end architecture bench;
