library ieee;
use ieee.std_logic_1164.all;

-- Declarations
package util_pkg is

	type alu_op_t is (and_op,or_op,xor_op,add_op,sub_op,lts_op,ltu_op,sll_op,srl_op,sra_op);
	type fwd_a_t is (dont_fwd_a, fwd_a_from_mem, fwd_a_from_wb );
	type fwd_b_t is (dont_fwd_b, fwd_b_from_mem, fwd_b_from_wb );
	function clogb2( depth : natural) return integer;

end package util_pkg;


-- Definitions
package body util_pkg is

	function clogb2( depth : natural) return integer is
	variable temp    : integer := depth;
	variable ret_val : integer := 0;
	begin
		 while temp > 1 loop
			  ret_val := ret_val + 1;
			  temp    := temp / 2;
		 end loop;
		return ret_val;
	end function;

end package body util_pkg;
