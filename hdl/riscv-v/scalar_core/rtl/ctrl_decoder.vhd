library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_decoder is
  port (                                -- from data_path
    opcode_i           : in  std_logic_vector (6 downto 0);
    funct3_i           : in  std_logic_vector(2 downto 0);
    -- to data_path
    branch_type_o      : out std_logic_vector(1 downto 0);
    mem_to_reg_o       : out std_logic_vector(1 downto 0);
    data_mem_we_o      : out std_logic;
    alu_src_b_o        : out std_logic;
    alu_src_a_o        : out std_logic;
    rd_we_o            : out std_logic;
    set_a_zero_o       : out std_logic;
    rs1_in_use_o       : out std_logic;
    rs2_in_use_o       : out std_logic;
    scalar_load_req_o  : out std_logic;
    scalar_store_req_o : out std_logic;
    vector_instr_o     : out std_logic;
    fencei_o           : out std_logic;
    alu_2bit_op_o      : out std_logic_vector(1 downto 0)

    );
end entity;

architecture behavioral of ctrl_decoder is
begin

  contol_dec : process(opcode_i, funct3_i)is
  begin
    --default
    branch_type_o      <= "00";
    mem_to_reg_o       <= "00";
    data_mem_we_o      <= '0';
    alu_src_b_o        <= '0';
    alu_src_a_o        <= '0';
    rd_we_o            <= '0';
    alu_2bit_op_o      <= "00";
    set_a_zero_o       <= '0';
    rs1_in_use_o       <= '0';
    rs2_in_use_o       <= '0';
    scalar_load_req_o  <= '0';
    scalar_store_req_o <= '0';
    vector_instr_o     <= '0';
    fencei_o           <= '0';
    case opcode_i is
      when "0000011" =>                 --LOAD
        mem_to_reg_o      <= "10";
        alu_src_b_o       <= '1';
        rd_we_o           <= '1';
        rs1_in_use_o      <= '1';
        scalar_load_req_o <= '1';
      when "0100011" =>                 --STORE
        data_mem_we_o      <= '1';
        alu_src_b_o        <= '1';
        rs1_in_use_o       <= '1';
        rs2_in_use_o       <= '1';
        scalar_store_req_o <= '1';
      when "0110011" =>                 --R type
        alu_2bit_op_o <= "10";
        rd_we_o       <= '1';
        rs1_in_use_o  <= '1';
        rs2_in_use_o  <= '1';
      when "0010011" =>                 --I type
        alu_2bit_op_o <= "11";
        alu_src_b_o   <= '1';
        rd_we_o       <= '1';
        rs1_in_use_o  <= '1';
      when "1100011" =>                 --B type
        alu_2bit_op_o <= "00";
        alu_src_a_o   <= '1';
        alu_src_b_o   <= '1';
        branch_type_o <= "01";
        rs1_in_use_o  <= '1';
        rs2_in_use_o  <= '1';
      when "1101111" =>                 -- JAL
        rd_we_o       <= '1';
        alu_src_a_o   <= '1';
        alu_src_b_o   <= '1';
        mem_to_reg_o  <= "01";
        branch_type_o <= "10";
      when "1100111" =>                 -- JALR
        rs1_in_use_o  <= '1';
        mem_to_reg_o  <= "01";
        rd_we_o       <= '1';
        alu_src_b_o   <= '1';
        branch_type_o <= "11";
      when "0010111" =>                 -- AUIPC
        rd_we_o     <= '1';
        alu_src_b_o <= '1';
        alu_src_a_o <= '1';
      when "0110111" =>                 -- LUI
        set_a_zero_o <= '1';
        rd_we_o      <= '1';
        alu_src_b_o  <= '1';
      when "0000111" =>                 -- vector load
        vector_instr_o <= '1';
        rs1_in_use_o   <= '1';
        rs2_in_use_o   <= '1';
      when "0100111" =>                 -- vector store
        vector_instr_o <= '1';
        rs1_in_use_o   <= '1';
        rs2_in_use_o   <= '1';
      when "1010111" =>                 -- vector arith                
        vector_instr_o <= '1';
        case funct3_i is
          when "100"=>
            rs1_in_use_o <= '1';
          when "111"=>
            rs1_in_use_o <= '1';
          when others =>
        end case;
      when "0001111" =>                 --FENCE.I
        fencei_o <= '1';
      when others =>
    end case;
  end process;

end architecture;

