library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;

entity scalar_core is
  port(
    -- Synchronization ports
    clk                 : in  std_logic;
    ce                  : in  std_logic;
    reset               : in  std_logic;
    instr_ready_i       : in  std_logic;
    data_ready_i        : in  std_logic;
    fencei_o            : out std_logic;
    pc_reg_o            : out std_logic_vector(31 downto 0); 
    -- Instruction memory interface
    instr_mem_address_o : out std_logic_vector(31 downto 0);
    instr_mem_read_i    : in  std_logic_vector(31 downto 0);

    --instr_mem_flush_o : out std_logic;
    --instr_mem_en_o    : out std_logic;

    ---------------------------- VECTOR CORE INTERFACE---------------------------
    -- Vector core status signals
    all_v_stores_executed_i : in  std_logic;
    all_v_loads_executed_i  : in  std_logic;
    vector_stall_i          : in  std_logic;
    -- Signals going to M_CU inside vector core
    scalar_load_req_o       : out std_logic;
    scalar_store_req_o      : out std_logic;

    -- Values of rs1 and rs2 from register bank going to Vector core
    v_instruction_o : out std_logic_vector(31 downto 0);
    rs1_o           : out std_logic_vector(31 downto 0);
    rs2_o           : out std_logic_vector(31 downto 0);
    --------------------------------------------------------------------------------------------


    -- Data memory interface      
    data_mem_address_o : out std_logic_vector(31 downto 0);
    data_mem_read_i    : in  std_logic_vector(31 downto 0);
    data_mem_write_o   : out std_logic_vector(31 downto 0);
    data_mem_we_o      : out std_logic_vector(3 downto 0);
    data_mem_re_o      : out std_logic);
end entity;

architecture structural of scalar_core is

  signal set_a_zero_s  : std_logic;
  signal mem_to_reg_s  : std_logic_vector(1 downto 0);
  signal load_type_s   : std_logic_vector(2 downto 0);
  signal alu_op_s      : alu_op_t;
  signal alu_src_b_s   : std_logic;
  signal alu_src_a_s   : std_logic;
  signal rd_we_s       : std_logic;
  signal pc_next_sel_s : std_logic;

  signal if_id_flush_s : std_logic;
  signal id_ex_flush_s : std_logic;

  signal alu_forward_a_s    : fwd_a_t;
  signal alu_forward_b_s    : fwd_b_t;
  signal branch_condition_s : std_logic;
  signal branch_op_s        : std_logic_vector(1 downto 0);

  signal pc_en_s    : std_logic;
  signal if_id_en_s : std_logic;

  signal instr_mem_id_s : std_logic_vector(31 downto 0);
  signal instr_mem_en_s : std_logic;
begin
  -- data_path instance
  data_path_1 : entity work.data_path
    port map (
      -- global synchronization signals
      clk                 => clk,
      ce                  => ce,
      instr_ready_i       => instr_ready_i,
      data_ready_i        => data_ready_i,
      reset               => reset,
      -- operands come from instruction memory
      instr_mem_address_o => instr_mem_address_o,
      instr_mem_read_i    => instr_mem_read_i,
      instr_mem_id_o      => instr_mem_id_s,
      -- interface towards data memory
      data_mem_address_o  => data_mem_address_o,
      data_mem_write_o    => data_mem_write_o,
      data_mem_read_i     => data_mem_read_i,

      -- Vector core interface
      v_instruction_o    => v_instruction_o,
      rs1_o              => rs1_o,
      rs2_o              => rs2_o,
      vector_stall_i     => vector_stall_i,
      -- control signals come from control path
      set_a_zero_i       => set_a_zero_s,
      mem_to_reg_i       => mem_to_reg_s,
      load_type_i        => load_type_s,
      alu_op_i           => alu_op_s,
      alu_src_b_i        => alu_src_b_s,
      alu_src_a_i        => alu_src_a_s,
      rd_we_i            => rd_we_s,
      pc_next_sel_i      => pc_next_sel_s,
      branch_op_i        => branch_op_s,
      -- control signals for forwaring
      alu_forward_a_i    => alu_forward_a_s,
      alu_forward_b_i    => alu_forward_b_s,
      branch_condition_o => branch_condition_s,
      -- control signals for flushing
      if_id_flush_i      => if_id_flush_s,
      id_ex_flush_i      => id_ex_flush_s,
      -- control signals for stalling
      pc_reg_o           => pc_reg_o,
      pc_en_i            => pc_en_s,
      if_id_en_i         => if_id_en_s);

  --flush current instruction
  --instr_mem_flush_o <= '1' when (if_id_flush_s = '1' or instr_ready_i = '0')                     else '0';
  -- stall currnet instruction
  instr_mem_en_s    <= '0' when (if_id_en_s = '0' or data_ready_i = '0' or vector_stall_i = '1') else '1';



  -- Control_path instance
  control_path_1 : entity work.control_path
    port map (
      -- global synchronization signals
      clk                     => clk,
      ce                      => ce,
      instr_ready_i           => instr_ready_i,
      data_ready_i            => data_ready_i,
      reset                   => reset,
      -- Vector core status signals
      all_v_stores_executed_i => all_v_stores_executed_i,
      all_v_loads_executed_i  => all_v_loads_executed_i,
      vector_stall_i          => vector_stall_i,
      -- Vector core control signals
      scalar_load_req_o       => scalar_load_req_o,
      scalar_store_req_o      => scalar_store_req_o,
      -- instruction is read from memory         
      instruction_i           => instr_mem_id_s,
      -- control signals are forwarded to data_path
      set_a_zero_o            => set_a_zero_s,
      mem_to_reg_o            => mem_to_reg_s,
      load_type_o             => load_type_s,
      alu_op_o                => alu_op_s,
      alu_src_b_o             => alu_src_b_s,
      alu_src_a_o             => alu_src_a_s,
      rd_we_o                 => rd_we_s,
      pc_next_sel_o           => pc_next_sel_s,
      branch_op_o             => branch_op_s,
      -- control signals for forwarding
      alu_forward_a_o         => alu_forward_a_s,
      alu_forward_b_o         => alu_forward_b_s,
      branch_condition_i      => branch_condition_s,
      -- control signals for flushing
      data_mem_we_o           => data_mem_we_o,
      if_id_flush_o           => if_id_flush_s,
      id_ex_flush_o           => id_ex_flush_s,
      -- control signals for stalling
      pc_en_o                 => pc_en_s,
      if_id_en_o              => if_id_en_s,
      fencei_o                => fencei_o,
      data_mem_re_o           => data_mem_re_o);


--instr_mem_flush_o <= if_id_flush_s;
--instr_mem_en_o <= if_id_en_s;
end architecture;
