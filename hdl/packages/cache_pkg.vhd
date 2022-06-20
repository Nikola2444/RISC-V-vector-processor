library ieee;
use ieee.std_logic_1164.all;

package cache_pkg is
	
	-- Integer log2 function
   	function clogb2 (depth: in natural) return integer;

end cache_pkg;

package body cache_pkg is

	function clogb2 (depth: in natural) return integer is
	variable temp    : integer := depth;
	variable ret_val : integer := 0;
	begin
		 while temp > 1 loop
			  ret_val := ret_val + 1;
			  temp    := temp / 2;
		 end loop;
		 return ret_val;
	end function;

end package body cache_pkg;
