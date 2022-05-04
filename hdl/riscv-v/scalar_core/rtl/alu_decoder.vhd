library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;

entity alu_decoder is
   port (
      -- from data_path
      alu_2bit_op_i : in  std_logic_vector(1 downto 0);
      funct3_i      : in  std_logic_vector (2 downto 0);
      funct7_i      : in  std_logic_vector (6 downto 0);
      -- to data_path
      alu_op_o      : out alu_op_t);
end entity;

architecture behavioral of alu_decoder is
	signal funct7_5_s : std_logic;
begin

 	funct7_5_s <= funct7_i(5);
   --finds appropriate alu operation from control_decoder output and funct fields
   alu_dec : process(alu_2bit_op_i, funct3_i, funct7_5_s)is
   begin
      --default
      alu_op_o <= add_op;
      case alu_2bit_op_i is
         when "00" =>
            alu_op_o <= add_op;
         --when "01" =>
            --case(funct3_i(2 downto 1))is
               --when "00" =>
                  --alu_op_o <= eq_op;
               --when "10" =>
                  --alu_op_o <= lts_op;
               --when others =>
                  --alu_op_o <= ltu_op;
            --end case;
         when others =>
            case funct3_i is
               when "000" =>
                  alu_op_o <= add_op;
                  if(alu_2bit_op_i = "10" and funct7_i(5) = '1') then
                        alu_op_o <= sub_op;
                     --elsif(funct7_i(0) = '1')then
                        --alu_op_o <= mulu_op;
                  end if;
               when "001" =>
                  alu_op_o <= sll_op;
                  --if(alu_2bit_op_i = "10" and funct7_i(0) = '1') then
                     --alu_op_o <= mulhs_op;
                  --end if;
               when "010" =>
                  alu_op_o <= lts_op;
                  --if(alu_2bit_op_i = "10" and funct7_i(0) = '1') then
                     --alu_op_o <= mulhsu_op;
                  --end if;
               when "011" =>
                  alu_op_o <= ltu_op;
                  --if(alu_2bit_op_i = "10" and funct7_i(0) = '1') then
                     --alu_op_o <= mulhu_op;
                  --end if;
               when "100" =>
                  alu_op_o <= xor_op;
                  --if(alu_2bit_op_i = "10" and funct7_i(0) = '1') then
                     --alu_op_o <= divs_op;
                  --end if;
               when "101" =>
                  alu_op_o <= srl_op;
                  if(funct7_i(5) = '1')then
                     alu_op_o <= sra_op;
                  end if;
                  --if(alu_2bit_op_i = "10" and funct7_i(0) = '1') then
                     --alu_op_o <= divu_op;
                  --end if;
               when "110" =>
                  alu_op_o <= or_op;
                  --if(alu_2bit_op_i = "10" and funct7_i(0) = '1') then
                     --alu_op_o <= rems_op;
                  --end if;
               when others =>
                  alu_op_o <= and_op;
                  --if(alu_2bit_op_i = "10" and funct7_i(0) = '1') then
                     --alu_op_o <= remu_op;
                  --end if;
            end case;
      end case;
   end process;

end architecture;
