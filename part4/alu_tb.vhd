library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;
 
entity alu_tb is
end alu_tb;
 
architecture behavior of alu_tb is 
 
component Alu
port(
	i_clk:			in std_logic;
	i_reset:			in std_logic;
	--
	i_operation:	in unsigned(3 downto 0);
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
	o_halfcarry:	out std_logic;
	o_sign:			out std_logic;
	o_overflow: 	out std_logic;
	o_negative:		out std_logic;
	o_zero:			out std_logic;
	o_carry:			out std_logic
);
end component;
    

-- Inputs
signal s_clk: std_logic := '0';
signal s_reset: std_logic := '0';

-- Outputs
signal s_result: unsigned(7 downto 0) := (others => '0');
signal s_halfcarry: std_logic := '0';
signal s_sign: std_logic := '0';
signal s_overflow: std_logic := '0';
signal s_negative: std_logic := '0';
signal s_zero: std_logic := '0';
signal s_carry: std_logic := '0';

-- Clock period definitions
constant k_clk_period : time := 10 ns;

signal s_operation_ix: std_logic_vector(3 downto 0) := (others => '0');
signal s_operation: std_logic_vector(3 downto 0) := (others => '0');
signal s_zero_input: std_logic := '0';
signal s_carry_input: std_logic := '0';
signal s_ignore_result: std_logic := '0';

signal s_rd: std_logic_vector(7 downto 0) := (others => '0');
signal s_rs: std_logic_vector(7 downto 0) := (others => '0');
signal s_rd2: std_logic_vector(7 downto 0) := (others => '0');
signal s_sreg: std_logic_vector(7 downto 0) := (others => '0');

signal s_rd2_actual: std_logic_vector(7 downto 0) := (others => '0');
signal s_sreg_actual: std_logic_vector(7 downto 0) := (others => '0');

-- Defines which bits of the status vector need to match between the reference and the ALU.
signal s_sreg_match_mask: std_logic_vector(7 downto 0) := (others => '0');

begin

 
-- Instantiate the Unit Under Test (UUT)
uut: Alu PORT MAP (
	i_clk => s_clk,
	i_reset => s_reset,
	i_operation => unsigned(s_operation), 
	i_op1 => unsigned(s_rd),
	i_op2 => unsigned(s_rs),
	o_result => s_result,
	--
	i_halfcarry => s_sreg(5), -- use value from reference data to check for 'unchanged'
	i_sign => s_sreg(4), 
	i_overflow => s_sreg(3), 
	i_negative => s_sreg(2), 
	i_zero => s_zero_input,
	i_carry => s_carry_input,
	--
	o_halfcarry => s_halfcarry,
	o_sign => s_sign,
	o_overflow => s_overflow,
	o_negative => s_negative,
	o_zero => s_zero,
	o_carry => s_carry
);

s_rd2_actual <= std_logic_vector(s_result);
s_sreg_actual <= "00" & s_halfcarry & s_sign & s_overflow & s_negative & s_zero & s_carry;

s_operation <= "0011" when s_operation_ix = "0001" -- ADD
			else "0111" when s_operation_ix = "0010" -- ADC
			else "0111" when s_operation_ix = "0011" -- ADC
			else "0110" when s_operation_ix = "0100" -- SUB
			else "0010" when s_operation_ix = "0101" -- SBC
			else "0010" when s_operation_ix = "0110" -- SBC
			else "1000" when s_operation_ix = "0111" -- AND
			else "1001" when s_operation_ix = "1000" -- EOR
			else "1010" when s_operation_ix = "1001" -- OR
			else "1011" when s_operation_ix = "1010" -- MOV
			else "0101" when s_operation_ix = "1011" -- CP
			else "0001" when s_operation_ix = "1100" -- CPC
			else "0001" when s_operation_ix = "1101" -- CPC
			else "0100" when s_operation_ix = "1110" -- CPSE
			else "0001";

-- For some instructions, we use fixed zero flag values in the stimuli.
s_zero_input <= '0' when s_operation_ix = "0010" -- ADC Z=0
			else '1' when s_operation_ix = "0011" -- ADC Z=1
			else '0' when s_operation_ix = "0101" -- SBC Z=0
			else '1' when s_operation_ix = "0110" -- SBC Z=1
			else '0' when s_operation_ix = "1100" -- CPC Z=0
			else '1' when s_operation_ix = "1101" -- CPC Z=1
			else s_sreg(1);

-- For some instructions, we use fixed carry flag values in the stimuli.
s_carry_input <= '0' when s_operation_ix = "0010" -- ADC C=0
			else '1' when s_operation_ix = "0011" -- ADC C=1
			else '0' when s_operation_ix = "0101" -- SBC C=0
			else '1' when s_operation_ix = "0110" -- SBC C=1
			else '0' when s_operation_ix = "1100" -- CPC C=0
			else '1' when s_operation_ix = "1101" -- CPC C=1
			else s_sreg(0);

-- For some instructions the ALU result is ignored and only the status is considered.
s_ignore_result <= '1' when s_operation_ix = "1011" -- CP
			else '1' when s_operation_ix = "1100" -- CPC C=0
			else '1' when s_operation_ix = "1101" -- CPC C=1
			else '1' when s_operation_ix = "1110" -- CPSE
			else '0';

clk :process
begin
	s_clk <= '0';
	wait for k_clk_period/2;
	s_clk <= '1';
	wait for k_clk_period/2;
end process;

test: process
	-- input file
	file infile: text is in  "stimuli/alu_dump.txt";
	variable inline: line;
	variable lineNr: integer := 0;
	variable operation: std_logic_vector(3 downto 0);
	variable rd: std_logic_vector(7 downto 0);
	variable rs: std_logic_vector(7 downto 0);
	variable rd2: std_logic_vector(7 downto 0);
	variable sreg: std_logic_vector(7 downto 0);
	-- output file
	file outfile: text is out "stimuli/alu_diff.txt";
	variable outline: line;
begin
	s_reset <= '1';
	wait for 100 ns;
	s_reset <= '0';

	while (not endfile(infile)) loop
		readline(infile, inline);
		lineNr := lineNr + 1;
		
		if inline'length > 5 then
		
			-- Read one line (= 1 set of input and reference output data)
			hread(inline, operation);
			hread(inline, rd);
			hread(inline, rs);
			hread(inline, rd2);
			hread(inline, sreg);

			-- Provide it to the ALU
			s_operation_ix <= operation;
			s_rd <= rd;
			s_rs <= rs;
			
			-- Reference output from the file
			s_rd2 <= rd2;
			s_sreg <= sreg;

			-- Let the ALU do its job...
			wait for 7 ns;	

			-- Do the reference and the result from the ALU match?
			if (s_ignore_result = '1' or rd2 = s_rd2_actual) and (sreg = s_sreg_actual) 
			then
				-- OK
			else
				write(outline, lineNr, right, 5);
				write(outline, " ", right, 1);
				hwrite(outline, rd, right, 3);
				write(outline, " ", right, 1);
				hwrite(outline, rs, right, 3);
				write(outline, " ", right, 1);

				hwrite(outline, rd2, right, 3);
				if (rd2 = s_rd2_actual) then
					write(outline, string'("="), right, 1);
				else
					write(outline, string'("*"), right, 1);				
				end if;
				hwrite(outline, s_rd2_actual, right, 2);
				write(outline, " ", right, 1);

				hwrite(outline, sreg, right, 3);
				if (sreg = s_sreg_actual) then
					write(outline, string'("="), right, 1);
				else
					write(outline, string'("*"), right, 1);
				end if;
				hwrite(outline, s_sreg_actual, right, 2);
				
				writeline(outfile, outline);			
			end if;
						 
			wait for 3 ns;
		else
			writeline(outfile, inline);
		end if;
	end loop;
end process;

end;
