library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
port (
	i_clk: 			in std_logic;
	i_reset_ext: 	in std_logic;
	-- data path
	i_A:				in unsigned(15 downto 0);
	i_Z:				in unsigned(15 downto 0);
	i_ALU_Z:			in std_logic;
	o_PMDATA:		out unsigned(15 downto 0)
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

component ProgramMemory is
port ( 
	i_clk:			in std_logic;
	i_addr:			in unsigned(15 downto 0);
	o_data:			out unsigned(15 downto 0)
);
end component;

component ControlUnit is
port ( 
	i_clk:			in std_logic;
	i_reset:			in std_logic;
	-- FSM inputs
	i_IR:				in unsigned(15 downto 0);
	i_ALU_Z:			in std_logic;
	-- control path outputs
	o_reset:			out std_logic;
	o_mode12K:		out std_logic_vector(1 downto 0);
	o_modeAddZA:	out std_logic_vector(1 downto 0);
	o_modePCZ:		out std_logic;
	o_loadPC:		out std_logic;
	o_loadIR:		out std_logic; 
	-- data path
	o_K:				out unsigned(15 downto 0)
);
end component;

-- connections between PM and CtrlFetch
signal s_pm_addr: unsigned(15 downto 0);
signal s_pm_data: unsigned(15 downto 0);

-- connections between CtrlFetch and ControlUnit
signal s_reset: std_logic;
signal s_mode12K: std_logic_vector(1 downto 0);
signal s_modeAddZA: std_logic_vector(1 downto 0);
signal s_modePCZ: std_logic;
signal s_loadPC: std_logic;
signal s_loadIR: std_logic;

signal s_IR: unsigned(15 downto 0);
signal s_K: unsigned(15 downto 0);

begin

CtrlFetch_0: component CtrlFetch
port map (
	i_clk => i_clk, 
	i_reset => s_reset, 
	-- control path
	i_mode12K => s_mode12K, 
	i_modeAddZA => s_modeAddZA, 
	i_modePCZ => s_modePCZ, 
	i_loadPC => s_loadPC, 
	i_loadIR => s_loadIR, 
	-- data path
	i_K => s_K, 
	i_A => i_A, 
	i_Z => i_Z, 
	o_IR => s_IR, 
	o_PMDATA => o_PMDATA,
	-- memory interface
	o_PMADDR => s_pm_addr, 
	i_PMDATA => s_pm_data
);

ProgramMemory_0: component ProgramMemory
port map (
	i_clk => i_clk, 
	i_addr => s_pm_addr, 
	o_data => s_pm_data
);

ControlUnit_0: component ControlUnit
port map (
	i_clk => i_clk, 
	i_reset => i_reset_ext, 
	-- FSM inputs
	i_IR => s_IR, 
	i_ALU_Z => i_ALU_Z, 
	-- control path outputs
	o_reset => s_reset, 
	o_mode12K => s_mode12K, 
	o_modeAddZA => s_modeAddZA, 
	o_modePCZ => s_modePCZ, 
	o_loadPC => s_loadPC, 
	o_loadIR => s_loadIR, 
	o_K => s_K
);

end Behavioral;
