library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity immediate is
   port (instruction_i        : in  std_logic_vector (31 downto 0);
         immediate_extended_o : out std_logic_vector (31 downto 0));
end entity;


architecture Behavioral of immediate is
   signal opcode           : std_logic_vector(6 downto 0);
   signal instruction_type : std_logic_vector(2 downto 0);
   signal funct3           : std_logic_vector(2 downto 0);
   signal extension        : std_logic_vector(19 downto 0);

   constant r_type_instruction : std_logic_vector(2 downto 0) := "000";
   constant i_type_instruction : std_logic_vector(2 downto 0) := "001";
   constant s_type_instruction : std_logic_vector(2 downto 0) := "010";
   constant b_type_instruction : std_logic_vector(2 downto 0) := "011";
   constant u_type_instruction : std_logic_vector(2 downto 0) := "100";
   constant j_type_instruction : std_logic_vector(2 downto 0) := "101";
   constant shamt_instruction  : std_logic_vector(2 downto 0) := "110";
   constant fence_ecall_ebreak : std_logic_vector(2 downto 0) := "111";

begin

   opcode    <= instruction_i(6 downto 0);
   extension <= (others => instruction_i(31));
   funct3    <= instruction_i(14 downto 12);

   -- based on opcode find instruction type
   process (opcode, funct3) is
   begin
      case opcode(6 downto 2) is
         when "01100" =>
            instruction_type <= r_type_instruction;
         when "00000" =>
            instruction_type <= i_type_instruction;
         when "00100" =>
            if(funct3 = "001" or funct3 = "101") then
               instruction_type <= shamt_instruction;
            else
               instruction_type <= i_type_instruction;
            end if;
         when "11001" =>
            instruction_type <= i_type_instruction;
         when "01000" =>
            instruction_type <= s_type_instruction;
         when "11000" =>
            instruction_type <= b_type_instruction;
         when "01101" =>
            instruction_type <= u_type_instruction;
         when "00101" =>
            instruction_type <= u_type_instruction;
         when "11011" =>
            instruction_type <= j_type_instruction;
         when others =>
            instruction_type <= fence_ecall_ebreak;
      end case;
   end process;

   -- based on instruction type from previous process extend data
   process (instruction_i, instruction_type, extension, funct3) is
   begin
      case instruction_type is
         when i_type_instruction =>
            immediate_extended_o <= extension & instruction_i(31 downto 20);
         when shamt_instruction =>
            immediate_extended_o <= std_logic_vector(to_unsigned(0, 27)) & instruction_i(24 downto 20);
         when b_type_instruction =>
            immediate_extended_o <= extension(18 downto 0) & instruction_i(31) & instruction_i(7) &
                                    instruction_i(30 downto 25) & instruction_i(11 downto 8) & '0';
         when s_type_instruction =>
            immediate_extended_o <= extension(19 downto 0) & instruction_i(31 downto 25) & instruction_i(11 downto 7);
         when u_type_instruction =>
            immediate_extended_o <= instruction_i(31 downto 12) & std_logic_vector(to_unsigned(0, 12));
         when j_type_instruction =>
            immediate_extended_o <= extension(10 downto 0) & instruction_i(31) & instruction_i(19 downto 12) &
                                    instruction_i(20) & instruction_i(30 downto 21) & '0';
         when others =>
            immediate_extended_o <= (others => '0');
      end case;
   end process;
end architecture;


