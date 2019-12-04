library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Responsible to provide general-purpose registers R0..R31, I/O memory and RAM.
entity RegisterFile_RAM is
port ( 
	i_clk:			in std_logic;
	i_reset:			in std_logic;
	-- control path
	i_we1:			in std_logic; -- write enable
	i_we2:			in std_logic;
	-- data path 1 -- 16 bit
	i_addr1:			in unsigned(10 downto 0);
	o_data1_16:		out unsigned(15 downto 0);
	o_data1_8:		out unsigned(7 downto 0);
	i_data1_16:		in unsigned(15 downto 0);
	-- data path 2 -- 8 bit
	i_addr2:			in unsigned(10 downto 0);
	o_data2:			out unsigned(7 downto 0);
	i_data2:			in unsigned(7 downto 0)
);
end RegisterFile_RAM;

architecture Behavioral of RegisterFile_RAM is

type REGS_RAM is array(255 downto 0) of unsigned(7 downto 0);
shared variable s_regs_ram: REGS_RAM := (others => (others => '0'));

signal s_addr1_base: unsigned(6 downto 0);
signal s_lsb1: std_logic := '0'; -- for demuxing
signal s_data1: std_logic_vector(15 downto 0) := (others => '0');
signal s_data2: std_logic_vector(7 downto 0) := (others => '0');

attribute box_type : string; 

component RAMB16_S9_S18
  -- synthesis translate_off
  generic (
    WRITE_MODE_A : string := "WRITE_FIRST";
    WRITE_MODE_B : string := "WRITE_FIRST"
  );
  -- synthesis translate_on
port (
  DOA : out STD_LOGIC_VECTOR (7 downto 0);
  DOB : out STD_LOGIC_VECTOR (15 downto 0);
  DOPA : out STD_LOGIC_VECTOR (0 downto 0);
  DOPB : out STD_LOGIC_VECTOR (1 downto 0);
  ADDRA : in STD_LOGIC_VECTOR (10 downto 0);
  ADDRB : in STD_LOGIC_VECTOR (9 downto 0); 
  CLKA : in STD_ULOGIC;
  CLKB  : in STD_ULOGIC;
  DIA : in STD_LOGIC_VECTOR (7 downto 0);
  DIB : in STD_LOGIC_VECTOR (15 downto 0);
  DIPA : in STD_LOGIC_VECTOR (0 downto 0);
  DIPB : in STD_LOGIC_VECTOR (1 downto 0);
  ENA   : in STD_ULOGIC;
  ENB   : in STD_ULOGIC;
  SSRA  : in STD_ULOGIC;
  SSRB  : in STD_ULOGIC;
  WEA   : in STD_ULOGIC;
  WEB   : in STD_ULOGIC
);
end component;
attribute box_type of RAMB16_S9_S18 : component is "black_box"; 


begin

o_data1_16 <= unsigned(s_data1);
o_data1_8  <= unsigned(s_data1(15 downto 8)) when s_lsb1 = '1' 
         else unsigned(s_data1(7 downto 0));
o_data2    <= unsigned(s_data2);

s_addr1_base <= i_addr1(7 downto 1);

BlockRam0: component RAMB16_S9_S18
port map (
  DOA => s_data2,
  DOB => s_data1,
  DOPA => open,
  DOPB => open,
  ADDRA => std_logic_vector(i_addr2),
  ADDRB => std_logic_vector(i_addr1(10 downto 1)),
  CLKA => i_clk,
  CLKB => i_clk,
  DIA => std_logic_vector(i_data2), 
  DIB => std_logic_vector(i_data1_16), 
  DIPA => "0", 
  DIPB => "00", 
  ENA => '1', 
  ENB => '1', 
  SSRA => i_reset, 
  SSRB => i_reset, 
  WEA => i_we2, 
  WEB => i_we1
);

process (i_clk)
begin
	if rising_edge(i_clk) then
		s_lsb1 <= i_addr1(0);
	end if;
end process;

end Behavioral;
