---------------------------------------------------------------------------
--  Copyright 2018 Vincent Camus all rights reserved                     --
--                                                                       --
--  Project: Carry Cut-Back Adder (CCBA) Source Code                     --
--  Authors: Vincent Camus (EPFL-ICLAB), vincent.camus@epfl.ch           --
--  License: BSD-2-Clause                                                --
--                                                                       --
--  File: ccba.vhd                                                       --
--  Description: CCBA entity description                                 --
--                                                                       --
--  Version: 1.0 (initial version)                                       --
--                                                                       --
--  Notes: no architecture nor configuration (for tool compatibility),   --
--  the architecture is defined by a string generic and is directly      --
--  instantiated with a "if-generate" statement                          --
---------------------------------------------------------------------------


------------------------------------------------------------------- packages and libraries

library ieee, work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ccba_pkg.all; -- unconstrained natural_array type definition


------------------------------------------------------------------- ccba entity declaration

entity ccba is
	generic (
		ADDER_ARCH    : string;        -- architecture ["multiplexed","input_induced"]
		ADDER_WIDTH   : natural;       -- adder bitwidth
		CUT_NUMBER    : natural;       -- number of cuts
		CUT_POSITIONS : natural_array; -- indexes of the cuts (carry-in/input of the cut stages)
		PROP_WIDTHS   : natural_array; -- widths of the PROP blocks
		ADD1_WIDTHS   : natural_array; -- distance between the cuts and the PROP
		SPEC_WIDTHS   : natural_array; -- widths of the SPEC blocks (multiplexed architecture only)
		CUT_TYPE      : character );   -- guess/input-override type ['0','1','a','b']
	port (                             
		a   : in  std_logic_vector (ADDER_WIDTH-1 downto 0);
		b   : in  std_logic_vector (ADDER_WIDTH-1 downto 0);
		cin : in  std_logic;
		s   : out std_logic_vector (ADDER_WIDTH downto 0) );
end entity ccba;


------------------------------------------------------------------- ccba rtl architecture

architecture rtl of ccba is
begin

	---------------------------------------- ccba "multiplexed" architecture
	
	arch_multiplexed: if (ADDER_ARCH = "multiplexed") generate
	
		-- array of start and end bit positions of ADD blocks
		constant ADD_POSITIONS : natural_array(0 to CUT_NUMBER+1) := 0 & CUT_POSITIONS & ADDER_WIDTH;
		
		-- ADD carry signals (including lower-part adder)
		signal add_cin   : std_logic_vector (CUT_NUMBER downto 0);
		signal add_cout  : std_logic_vector (CUT_NUMBER downto 0);
		
		-- SPEC speculated carry signals
		signal spec_cout : std_logic_vector (CUT_NUMBER downto 1);
	
	begin
	
		-- carries of boundary ADD blocks
		add_cin(0)     <= cin;
		s(ADDER_WIDTH) <= add_cout(CUT_NUMBER);
		
		-- ADD blocks
		gen_add: for i in CUT_NUMBER downto 0 generate
			process (
				a(ADD_POSITIONS(i+1)-1 downto ADD_POSITIONS(i)),
				b(ADD_POSITIONS(i+1)-1 downto ADD_POSITIONS(i)),
				add_cin(i) )
				
				-- variables
				variable s_big : std_logic_vector(ADD_POSITIONS(i+1) downto ADD_POSITIONS(i));
				
			begin

				-- addition
				s_big := std_logic_vector(
					unsigned('0' & a(ADD_POSITIONS(i+1)-1 downto ADD_POSITIONS(i)))+
					unsigned('0' & b(ADD_POSITIONS(i+1)-1 downto ADD_POSITIONS(i)))+
					(add_cin(i) & "") );

				-- output signals
				s(ADD_POSITIONS(i+1)-1 downto ADD_POSITIONS(i)) <= s_big(ADD_POSITIONS(i+1)-1 downto ADD_POSITIONS(i));
				add_cout(i) <= s_big(ADD_POSITIONS(i+1));

			end process;
		end generate;
		
		-- PROP blocks and cuts
		gen_prop: for i in CUT_NUMBER downto 1 generate
			process (
				a(ADD_POSITIONS(i)+PROP_WIDTHS(i-1)+ADD1_WIDTHS(i-1) downto ADD_POSITIONS(i-1)+ADD1_WIDTHS(i-1)+1),
				b(ADD_POSITIONS(i)+PROP_WIDTHS(i-1)+ADD1_WIDTHS(i-1) downto ADD_POSITIONS(i-1)+ADD1_WIDTHS(i-1)+1),
				spec_cout(i),
				add_cout(i-1) )
				
				-- variables
				variable propagates : std_logic_vector(ADD_POSITIONS(i)+ADD1_WIDTHS(i-1)+PROP_WIDTHS(i-1)
					downto ADD_POSITIONS(i)+ADD1_WIDTHS(i-1)+1);
			
			begin

				-- getting propagate values for PROP bits
				propagates := a(ADD_POSITIONS(i)+PROP_WIDTHS(i-1)+ADD1_WIDTHS(i-1) downto ADD_POSITIONS(i)+ADD1_WIDTHS(i-1)+1) xor
					 b(ADD_POSITIONS(i)+PROP_WIDTHS(i-1)+ADD1_WIDTHS(i-1) downto ADD_POSITIONS(i)+ADD1_WIDTHS(i-1)+1);

				-- multiplexing carry of ADD block 
				if (propagates = (propagates'range => '1'))
					then add_cin(i) <= spec_cout(i);  -- cut
					else add_cin(i) <= add_cout(i-1); -- no cut
				end if;

			end process;
		end generate;

		-- SPEC blocks and guess signals
		gen_spec: for i in CUT_NUMBER downto 1 generate
			process (
				a(ADD_POSITIONS(i)-1 downto ADD_POSITIONS(i)-SPEC_WIDTHS(i-1)-1),
				b(ADD_POSITIONS(i)-1 downto ADD_POSITIONS(i)-SPEC_WIDTHS(i-1)-1),
				cin )
				
				-- variables
				variable guess : std_logic;
				variable s_big : std_logic_vector(ADD_POSITIONS(i) downto ADD_POSITIONS(i)-SPEC_WIDTHS(i-1));

			begin

				-- generating guess signal
				case CUT_TYPE is
					when '0'     => guess := '0';
					when '1'     => guess := '1';
					when 'a'|'A' => guess := a(ADD_POSITIONS(i)-SPEC_WIDTHS(i-1)-1);
					when 'b'|'B' => guess := b(ADD_POSITIONS(i)-SPEC_WIDTHS(i-1)-1);
					when others  => report "No corresponding guess char" severity failure;
				end case;

				-- using addition for PROP internal carry propagation
				s_big := std_logic_vector(
					unsigned('0' & a(ADD_POSITIONS(i)-1 downto ADD_POSITIONS(i)-SPEC_WIDTHS(i-1)))+
					unsigned('0' & b(ADD_POSITIONS(i)-1 downto ADD_POSITIONS(i)-SPEC_WIDTHS(i-1)))+
					(guess & "") );

				-- output carry signal
				spec_cout(i) <= s_big(ADD_POSITIONS(i));

			end process;
		end generate;

	end generate; -- end of "multiplexed" architecture
	
	---------------------------------------- ccba "input_induced" architecture
	
	arch_input_induced: if (ADDER_ARCH = "input_induced") generate

		-- real input signals to the adder block
		signal a_buf : std_logic_vector (ADDER_WIDTH-1 downto 0);
		signal b_buf : std_logic_vector (ADDER_WIDTH-1 downto 0);

	begin

		-- adder block
		s <= std_logic_vector( unsigned('0' & a_buf) + unsigned('0' & b_buf) + (cin & "") );
		
		-- PROP blocks and input-induced cuts
		process ( a, b, cin )
			
			-- variables
			variable propagates : std_logic_vector(ADDER_WIDTH-1 downto 0);
			variable overwrites : std_logic_vector(CUT_NUMBER-1 downto 0);
			
		begin
			
			-- prop
			propagates := a xor b;
			
			-- default input signals to the adder block
			a_buf <= a;
			b_buf <= b;
			
			-- overwriting input signals at cutting positions
			for i in CUT_NUMBER-1 downto 0 loop
				
				-- generating overwrites signals
				case CUT_TYPE is
					when 'k'|'K'|'0' => overwrites(i) := '0';
					when 'g'|'G'|'1' => overwrites(i) := '1';
					when 'a'|'A'     => overwrites(i) := a(CUT_POSITIONS(i));
					when 'b'|'B'     => overwrites(i) := b(CUT_POSITIONS(i));
					when others => report "No corresponding cut type char" severity failure;
				end case;

				-- overwriting adder inputs to induce a cut in the carry chain
				if ( propagates(CUT_POSITIONS(i)+PROP_WIDTHS(i)+ADD1_WIDTHS(i) downto CUT_POSITIONS(i)+ADD1_WIDTHS(i)+1)
					= (CUT_POSITIONS(i)+PROP_WIDTHS(i)+ADD1_WIDTHS(i) downto CUT_POSITIONS(i)+ADD1_WIDTHS(i)+1 => '1') )

				then
					a_buf(CUT_POSITIONS(i)) <= overwrites(i);
					b_buf(CUT_POSITIONS(i)) <= overwrites(i);
				end if;

			end loop;
		end process;

	end generate; -- end of "input_induced" architecture
			
end architecture rtl;
