library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity top_tb is
end top_tb;
 
architecture behavior of top_tb is 
 
component top is
port (
	i_clk: 			in std_logic;
	i_reset_ext: 	in std_logic;
	-- data path
	i_A:				in unsigned(15 downto 0);
	i_ALU_Z:			in std_logic;
	o_PMDATA:		out unsigned(15 downto 0);
	-- debug
	o_ALU_result:	out unsigned(7 downto 0);
	o_ALU_sreg:		out std_logic_vector(5 downto 0)
);
end component;
    

--Inputs
signal i_clk : std_logic := '0';
signal i_reset_ext : std_logic := '0';
signal i_A : unsigned(15 downto 0) := (others => '0');
signal i_ALU_Z : std_logic := '0'; -- if set to '1', program enters infinite loop at address 2 instead of 3

--Outputs
signal o_PMDATA : unsigned(15 downto 0);

signal s_ALU_result: unsigned(7 downto 0);
signal s_ALU_sreg: std_logic_vector(5 downto 0);

-- Clock period definitions
constant i_clk_period : time := 10 ns;
 
begin
 
-- Instantiate the Unit Under Test (UUT)
uut: top PORT MAP (
	i_clk => i_clk,
	i_reset_ext => i_reset_ext,
	i_A => i_A,
	i_ALU_Z => i_ALU_Z,
	o_PMDATA => o_PMDATA, 
	o_ALU_result => s_ALU_result, 
	o_ALU_sreg => s_ALU_sreg
);

-- Clock process definitions
i_clk_process: process
begin
	i_clk <= '0';
	wait for i_clk_period/2;
	i_clk <= '1';
	wait for i_clk_period/2;
end process;

-- Stimulus process
stim_proc: process
begin		
	-- hold reset state for 100 ns.
	wait for 100 ns;	

	wait for i_clk_period*10;

	-- insert stimulus here 

	wait;
end process;

END;
