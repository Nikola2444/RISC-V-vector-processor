LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.math_real.all;
use work.util_pkg.all;


ENTITY ALU IS
   GENERIC(
      WIDTH : NATURAL := 32);
   PORT(
      a_i    : in STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --first input
      b_i    : in STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --second input
      op_i   : in alu_op_t; --operation select
      res_o  : out STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)); --result
      --zero_o : out STD_LOGIC; --zero flag
      --of_o   : out STD_LOGIC; --overflow flag
END ALU;

ARCHITECTURE behavioral OF ALU IS

   constant  l2WIDTH : natural := integer(ceil(log2(real(WIDTH))));
   signal    lts_res,ltu_res,add_res,sub_res,or_res,and_res,res_s,xor_res  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
   signal    eq_res,sll_res,srl_res,sra_res : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
   --signal    divu_res,divs_res,rems_res,remu_res : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
   --signal    muls_res,mulu_res : STD_LOGIC_VECTOR(2*WIDTH-1 DOWNTO 0);	
   --signal    mulsu_res : STD_LOGIC_VECTOR(2*WIDTH+1 DOWNTO 0);

   
BEGIN

   -- addition
   add_res <= std_logic_vector(unsigned(a_i) + unsigned(b_i));
   -- subtraction
   sub_res <= std_logic_vector(unsigned(a_i) - unsigned(b_i));
   -- and gate
   and_res <= a_i and b_i;
   -- or gate
   or_res <= a_i or b_i;
   -- xor gate
   xor_res <= a_i xor b_i;
   -- equal
   --eq_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (signed(a_i) = signed(b_i)) else
             --std_logic_vector(to_unsigned(0,WIDTH));
   -- less then signed
   lts_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (signed(a_i) < signed(b_i)) else
              std_logic_vector(to_unsigned(0,WIDTH));
   -- less then unsigned
   ltu_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (unsigned(a_i) < unsigned(b_i)) else
              std_logic_vector(to_unsigned(0,WIDTH));
   --shift results
   sll_res <= std_logic_vector(shift_left(unsigned(a_i), to_integer(unsigned(b_i(l2WIDTH downto 0)))));
   srl_res <= std_logic_vector(shift_right(unsigned(a_i), to_integer(unsigned(b_i(l2WIDTH downto 0)))));
   sra_res <= std_logic_vector(shift_right(signed(a_i), to_integer(unsigned(b_i(l2WIDTH downto 0)))));
   --multiplication
   --muls_res <= std_logic_vector(signed(a_i)*signed(b_i));
   --mulsu_res <= std_logic_vector(signed(a_i(WIDTH-1) & a_i)*signed('0' & b_i)); 
   --mulu_res <= std_logic_vector(unsigned(a_i)*unsigned(b_i));
   --division
   --divs_res <= std_logic_vector(signed(a_i)/signed(b_i)) when b_i /= std_logic_vector(to_unsigned(0,WIDTH)) else
   --            (others => '1');
   --divu_res <= std_logic_vector(unsigned(a_i)/unsigned(b_i)) when b_i /= std_logic_vector(to_unsigned(0,WIDTH)) else
   --            (others => '1');
   --mode
   --rems_res <= std_logic_vector(signed(a_i) rem signed(b_i)) when b_i /= std_logic_vector(to_unsigned(0,WIDTH)) else
   --            (others => '1');
   --remu_res <= std_logic_vector(unsigned(a_i) rem unsigned(b_i)) when b_i /= std_logic_vector(to_unsigned(0,WIDTH)) else
   --           (others => '1');
   
   -- SELECT RESULT
   res_o <= res_s;
   with op_i select
      res_s <= and_res when and_op, --and
      or_res when or_op, --or
      xor_res when xor_op, --xor
      add_res when add_op, --add (changed opcode)
      sub_res when sub_op, --sub
      --eq_res when eq_op, -- set equal
      lts_res when lts_op, -- set less than signed
      ltu_res when ltu_op, -- set less than unsigned
      sll_res when sll_op, -- shift left logic
      srl_res when srl_op, -- shift right logic
      sra_res when sra_op, -- shift right arithmetic
      --mulu_res(WIDTH-1 downto 0) when mulu_op, -- multiply lower
      --muls_res(2*WIDTH-1 downto WIDTH) when mulhs_op, -- multiply higher signed
      --mulsu_res(2*WIDTH-1 downto WIDTH) when mulhsu_op, -- multiply higher signed and unsigned
      --mulu_res(2*WIDTH-1 downto WIDTH) when mulhu_op, -- multiply higher unsigned
      --divu_res when divu_op, -- divide unsigned
      --divs_res when divs_op, -- divide signed
      --remu_res when remu_op, -- reminder signed
      --rems_res when rems_op, -- reminder signed
      (others => '1') when others; 


   -- flag outputs
   -- set zero output flag when result is zero
   --zero_o <= '1' when res_s = std_logic_vector(to_unsigned(0,WIDTH)) else
             --'0';
   -- overflow happens when inputs have same sign, and output has different
   --of_o <= '1' when ((op_i=add_op and (a_i(WIDTH-1)=b_i(WIDTH-1)) and ((a_i(WIDTH-1) xor res_s(WIDTH-1))='1')) or (op_i=sub_op and (a_i(WIDTH-1)=res_s(WIDTH-1)) and ((a_i(WIDTH-1) xor b_i(WIDTH-1))='1'))) else '0';


END behavioral;
