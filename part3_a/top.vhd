library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
port (
	i_clk: in std_logic;
	i_reset: in std_logic;
	-- control path
	i_mode12K:		in std_logic_vector(1 downto 0);
	i_modeAddZA:	in std_logic_vector(1 downto 0);
	i_modePCZ:		in std_logic;
	i_loadPC:		in std_logic;
	i_loadIR:		in std_logic;
	-- data path
	i_K:				in unsigned(15 downto 0);
	i_A:				in unsigned(15 downto 0);
	i_Z:				in unsigned(15 downto 0);
	o_IR:				out unsigned(15 downto 0);
	o_PMDATA:		out unsigned(15 downto 0);
	-- memory interface
	o_PMADDR:		out unsigned(15 downto 0);
	i_PMDATA:		in unsigned(15 downto 0)
);
end top;

architecture Behavioral of top is

component CtrlFetch is
port ( 
	i_clk:			in std_logic;
	i_reset:			in std_logic;
	-- control path
	i_mode12K:		in std_logic_vector(1 downto 0);
	i_modeAddZA:	in std_logic_vector(1 downto 0);
	i_modePCZ:		in std_logic;
	i_loadPC:		in std_logic;
	i_loadIR:		in std_logic;
	-- data path
	i_K:				in unsigned(15 downto 0);
	i_A:				in unsigned(15 downto 0);
	i_Z:				in unsigned(15 downto 0);
	o_IR:				out unsigned(15 downto 0);
	o_PMDATA:		out unsigned(15 downto 0);
	-- memory interface
	o_PMADDR:		out unsigned(15 downto 0);
	i_PMDATA:		in unsigned(15 downto 0)
);
end component;

-- signal s_pc: unsigned(15 downto 0);

begin

CtrlFetch_0: component CtrlFetch
port map (
	i_clk => i_clk, 
	i_reset => i_reset, 
	i_mode12K => i_mode12K, 
	i_modeAddZA => i_modeAddZA, 
	i_modePCZ => i_modePCZ, 
	i_loadPC => i_loadPC, 
	i_loadIR => i_loadIR, 
	i_K => i_K, 
	i_A => i_A, 
	i_Z => i_Z, 
	o_IR => o_IR, 
	o_PMDATA => o_PMDATA, 
	o_PMADDR => o_PMADDR, 
	i_PMDATA => i_PMDATA
);

end Behavioral;
