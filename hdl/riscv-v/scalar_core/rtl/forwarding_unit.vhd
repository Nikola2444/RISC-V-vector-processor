library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;


entity forwarding_unit is
   port (
      -- mem inputs
      rd_we_mem_i        : in  std_logic;
      rd_address_mem_i   : in  std_logic_vector(4 downto 0);
      -- wb inputs
      rd_we_wb_i         : in  std_logic;
      rd_address_wb_i    : in  std_logic_vector(4 downto 0);
      -- forward control outputs
      alu_forward_a_o    : out fwd_a_t;
      alu_forward_b_o    : out fwd_b_t;
      -- ex inputs
      rs1_address_ex_i   : in  std_logic_vector(4 downto 0);
      rs2_address_ex_i   : in  std_logic_vector(4 downto 0));
end entity;

architecture Behavioral of forwarding_unit is
   --constant zero_c : std_logic_vector (4 downto 0) := std_logic_vector(to_unsigned(0, 5));
begin

   --process that checks whether forwarding for instructions in EX stage is needed or not.
   -- forwarding from MEM stage has advantage over forwading information from WB
   -- stage, because information contained there is more recent than in WB.
   forward_proc : process(rd_we_mem_i, rd_address_mem_i, rd_we_wb_i, rd_address_wb_i,rs1_address_ex_i, rs2_address_ex_i)is
   begin
      alu_forward_a_o <= dont_fwd_a;
      alu_forward_b_o <= dont_fwd_b;
      -- forwarding from WB stage
      if (rd_we_wb_i = '1' )then -- and rd_address_wb_i /= zero_c
         if (rd_address_wb_i = rs1_address_ex_i)then
            alu_forward_a_o <= fwd_a_from_wb;
         end if;
         if(rd_address_wb_i = rs2_address_ex_i)then
            alu_forward_b_o <= fwd_b_from_wb;
         end if;
      end if;
      -- forwarding from MEM stage
      if (rd_we_mem_i = '1' )then -- and rd_address_mem_i /= zero_c
         if (rd_address_mem_i = rs1_address_ex_i)then
            alu_forward_a_o <= fwd_a_from_mem;
         end if;
         if (rd_address_mem_i = rs2_address_ex_i)then
            alu_forward_b_o <= fwd_b_from_mem;
         end if;
      end if;
   end process;


end architecture;
