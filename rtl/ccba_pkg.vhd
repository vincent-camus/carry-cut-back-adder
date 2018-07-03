---------------------------------------------------------------------------
--  Copyright 2018 Vincent Camus all rights reserved                     --
--                                                                       --
--  Project: Carry Cut-Back Adder (CCBA) Source Code                     --
--  Authors: Vincent Camus (EPFL-ICLAB), vincent.camus@epfl.ch           --
--  License: BSD-3-Clause-Clear                                          --
--                                                                       --
--  File: ccba_pkg.vhd                                                   --
--  Description: unconstrained natural_array type definition             --
--                                                                       --
--  Version: 1.0 (initial version)                                       --
---------------------------------------------------------------------------


------------------------------------------------------------------- ccba_pkg package

package ccba_pkg is

    type natural_array is array (natural range <>) OF natural range 0 to 255;
	
end package ccba_pkg;

