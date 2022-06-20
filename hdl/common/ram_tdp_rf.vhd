
--  Xilinx True Dual Port RAM Byte Write Read First Single Clock
--  This code implements a parameterizable true dual port memory (both ports can read and write).
--  The behavior of this RAM is when data is written, the prior memory contents at the write
--  address are presented on the output port.  If the output data is
--  not needed during writes or the last read value is desired to be retained,
--  it is suggested to use a no change RAM as it is more power efficient.
--  If a reset or enable is not necessary, it may be tied off or removed from the code.
--  Modify the parameters for the desired RAM characteristics.
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cache_pkg.all;
USE std.textio.all;

entity RAM_tdp_rf is
generic (

    RAM_WIDTH : integer := 26;                      -- Specify RAM data width
    RAM_DEPTH : integer := 64;                    -- Specify RAM depth (number of entries)
    RAM_PERFORMANCE : string := "HIGH_PERFORMANCE";      -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    INIT_FILE : string := ""            -- Specify name/location of RAM initialization file if using one (leave blank if not)
    );

port (
        addra : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
        addrb : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port B Address bus, width determined from RAM_DEPTH
        dina  : in std_logic_vector(RAM_WIDTH-1 downto 0);		  -- Port A RAM input data
        dinb  : in std_logic_vector(RAM_WIDTH-1 downto 0);		  -- Port B RAM input data
        clk  : in std_logic;                       			  -- Clock
        wea   : in std_logic;	  					-- Port A Write enable
        web   : in std_logic; 	  					-- Port B Write enable
        ena   : in std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        enb   : in std_logic;                       			  -- Port B RAM Enable, for additional power savings, disable port when not in use
        rsta  : in std_logic;                       			  -- Port A Output reset (does not affect memory contents)
        rstb  : in std_logic;                       			  -- Port B Output reset (does not affect memory contents)
        regcea: in std_logic;                       			  -- Port A Output register enable
        regceb: in std_logic;                       			  -- Port B Output register enable
        douta : out std_logic_vector(RAM_WIDTH-1 downto 0);   --  Port A RAM output data
        doutb : out std_logic_vector(RAM_WIDTH-1 downto 0)   	--  Port B RAM output data
    );

end RAM_tdp_rf;

architecture rtl of RAM_tdp_rf is

constant C_RAM_WIDTH : integer := RAM_WIDTH;                                                   -- Specify RAM data width
constant C_RAM_DEPTH : integer := RAM_DEPTH;
constant C_RAM_PERFORMANCE : string := RAM_PERFORMANCE;
constant C_INIT_FILE : string := INIT_FILE;


signal douta_reg : std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0');
signal doutb_reg : std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0');

type ram_type is array (0 to C_RAM_DEPTH-1) of std_logic_vector (RAM_WIDTH-1 downto 0);          -- 2D Array Declaration for RAM signal

signal ram_data_a : std_logic_vector(RAM_WIDTH-1 downto 0) ;
signal ram_data_b : std_logic_vector(RAM_WIDTH-1 downto 0) ;

-- The folowing code either initializes the memory values to a specified file or to all zeros to match hardware

impure function initramfromfile (ramfilename : in string) return ram_type is
file ramfile	: text is in ramfilename;
variable ramfileline : line;
variable i : integer := 0;

variable ram_array_v	: ram_type;
variable bitvec : bit_vector(RAM_WIDTH-1 downto 0);
begin
	 ram_array_v := (others => (others => '0'));
    while not endfile(ramfile) loop
        readline (ramfile, ramfileline);
        read (ramfileline, bitvec);
        ram_array_v(i) := to_stdlogicvector(bitvec);
        i:=i+1;
    end loop;
    return ram_array_v;
end function;

impure function init_from_file_or_zeroes(ramfile : string) return ram_type is
begin
    if ramfile = "" then
        return (others => (others => '0'));
    else
        return InitRamFromFile(ramfile) ;
    end if;
end;

-- Following code defines RAM
shared variable ram_array_v : ram_type := init_from_file_or_zeroes(C_INIT_FILE);
attribute ram_style : string;
attribute ram_style of ram_array_v : variable is "block";

begin

process(clk)
begin
	if(clk'event and clk = '1') then
		if(ena = '1') then
			ram_data_a <= ram_array_v(to_integer(unsigned(addra)));
			if(wea = '1') then
				ram_array_v(to_integer(unsigned(addra))) := dina;
			end if;
		end if;
	end if;
end process;

process(clk)
begin
	if(clk'event and clk = '1') then
		if(enb = '1') then	  
			ram_data_b <= ram_array_v(to_integer(unsigned(addrb)));
			if(web = '1') then
				ram_array_v(to_integer(unsigned(addrb))):= dinb;
			end if;
		end if;
	end if;
end process;

--  Following code generates LOW_LATENCY (no output register)
--  Following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing

no_output_register : if C_RAM_PERFORMANCE = "LOW_LATENCY" generate
    douta <= ram_data_a;
    doutb <= ram_data_b;
end generate;

--  Following code generates HIGH_PERFORMANCE (use output register)
--  Following is a 2 clock cycle read latency with improved clock-to-out timing

output_register : if C_RAM_PERFORMANCE = "HIGH_PERFORMANCE"  generate
process(clk)
begin
    if(clk'event and clk = '1') then
        if(rsta = '1') then
            douta_reg <= (others => '0');
        elsif(regcea = '1') then
            douta_reg <= ram_data_a;
        end if;
    end if;
end process;
douta <= douta_reg;

process(clk)
begin
    if(clk'event and clk = '1') then
        if(rstb = '1') then
            doutb_reg <= (others => '0');
        elsif(regceb = '1') then
            doutb_reg <= ram_data_b;
        end if;
    end if;
end process;
doutb <= doutb_reg;

end generate;
end rtl;


							
							
