library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
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
	o_writeReg:		out std_logic;
	o_ldi:			out std_logic;
	-- data path
	o_K:				out unsigned(15 downto 0)
);
end component;

-- Responsible to provide general-purpose registers R0..R31.
component RegisterFile is
port ( 
	i_clk:			in std_logic;
	i_reset:			in std_logic;
	-- control path
	i_write:			in std_logic;
	-- data path
	i_addr_r1:		in unsigned(4 downto 0);
	i_addr_r2:		in unsigned(4 downto 0);
	i_addr_w:		in unsigned(4 downto 0);
	o_data_r1:		out unsigned(7 downto 0);
	o_data_r2:		out unsigned(7 downto 0);
	i_data_w:		in unsigned(7 downto 0);
	o_x:				out unsigned(15 downto 0);
	o_y:				out unsigned(15 downto 0);
	o_z:				out unsigned(15 downto 0)
);
end component;

-- Responsible for arithmetic and logic operations on 2 operands.
component Alu is
port ( 
	i_clk:			in std_logic;
	i_reset:			in std_logic;
	-- control path
	i_operation:	in unsigned(3 downto 0);
	-- data path
	i_op1:			in unsigned(7 downto 0);
	i_op2:			in unsigned(7 downto 0);
	o_result:		out unsigned(7 downto 0);
	--
	i_halfcarry:	in std_logic;
	i_sign:			in std_logic;
	i_overflow:		in std_logic;
	i_negative:		in std_logic;
	i_zero:			in std_logic;
	i_carry:			in std_logic;
	--
	o_halfcarry:	out std_logic;	-- unsigned
	o_sign:			out std_logic;	-- 2's complement
	o_overflow:		out std_logic; -- 2's complement
	o_negative:		out std_logic; -- 2's complement
	o_zero:			out std_logic; -- arith+logic
	o_carry:			out std_logic  -- unsigned
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
signal s_ldi: std_logic;

signal s_IR: unsigned(15 downto 0);
signal s_K: unsigned(15 downto 0);

-- connections to the register file
signal s_reg_write: std_logic := '0';
signal s_reg_addr_r1: unsigned(4 downto 0) := (others => '0');
signal s_reg_addr_r2: unsigned(4 downto 0) := (others => '0'); 
signal s_reg_addr_w: unsigned(4 downto 0) := (others => '0');
signal s_reg_data_r1: unsigned(7 downto 0) := (others => '0');
signal s_reg_data_r2: unsigned(7 downto 0) := (others => '0');
signal s_reg_data_w: unsigned(7 downto 0) := (others => '0');

signal s_x: unsigned(15 downto 0) := (others => '0');
signal s_y: unsigned(15 downto 0) := (others => '0');
signal s_z: unsigned(15 downto 0) := (others => '0');

-- connections to the ALU
signal s_alu_operation: unsigned(3 downto 0) := (others => '0');
signal s_alu_op1: unsigned(7 downto 0) := (others => '0');
signal s_alu_op2: unsigned(7 downto 0) := (others => '0');
signal s_alu_result: unsigned(7 downto 0) := (others => '0');
signal s_alu_sreg: std_logic_vector(5 downto 0) := (others => '0');

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
	i_Z => s_z, 
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
	o_writeReg => s_reg_write, 
	o_ldi => s_ldi, 
	o_K => s_K
);

-- Responsible to provide general-purpose registers R0..R31.
RegisterFile_0: component RegisterFile
port map ( 
	i_clk => i_clk, 
	i_reset => s_reset, 
	-- control path
	i_write => s_reg_write, 
	-- data path
	i_addr_r1 => s_reg_addr_r1, 
	i_addr_r2 => s_reg_addr_r2, 
	i_addr_w => s_reg_addr_w, 
	o_data_r1 => s_reg_data_r1, 
	o_data_r2 => s_reg_data_r2, 
	i_data_w => s_reg_data_w, 
	o_x => s_x, 
	o_y => s_y, 
	o_z => s_z
);

s_reg_addr_r1 <= s_IR(8 downto 4); -- Rd
s_reg_addr_r2 <= s_IR(9) & s_IR(3 downto 0); -- Rr

-- LDI can only address registers R16 to R31
s_reg_addr_w(4) <= '1' when s_ldi = '1' else s_IR(8);
s_reg_addr_w(3 downto 0) <= s_IR(7 downto 4);  -- Rd

-- LDI stores a constant from IR into the register
s_reg_data_w <= s_IR(11 downto 8) & s_IR(3 downto 0) when s_ldi = '1'
	else s_alu_result;

-- Responsible for arithmetic and logic operations on 2 operands.
Alu_0: component Alu
port map ( 
	i_clk => i_clk, 
	i_reset => s_reset, 
	-- control path
	i_operation => s_alu_operation, 
	-- data path
	i_op1 => s_alu_op1, 
	i_op2 => s_alu_op2, 
	o_result => s_alu_result, 
	--
	i_halfcarry => '0', -- todo
	i_sign => '0', -- todo
	i_overflow => '0', -- todo
	i_negative => '0', -- todo
	i_zero => '0', -- todo
	i_carry => '0', -- todo
	--
	o_halfcarry => s_alu_sreg(5), 
	o_sign => s_alu_sreg(4), 
	o_overflow => s_alu_sreg(3), 
	o_negative => s_alu_sreg(2),
	o_zero => s_alu_sreg(1), 
	o_carry => s_alu_sreg(0)
);

s_alu_operation <= s_IR(13 downto 10);
s_alu_op1 <= s_reg_data_r1;
s_alu_op2 <= s_reg_data_r2;

o_ALU_result <= s_alu_result;
o_ALU_sreg <= s_alu_sreg;

end Behavioral;
