library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControlUnit is
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
end ControlUnit;

architecture Behavioral of ControlUnit is

type PROGMEM is array(7 downto 0) of unsigned(15 downto 0);
type ControlUnitState is (
	CUS_RESET, 			-- initial state, reset all registers
	CUS_FETCH_1, 		-- fetch the next instruction into IR
	CUS_FETCH_2, 		--  (wait for memory)
	CUS_DECODE, 		-- decode the instruction in IR
	CUS_EXEC_IJMP, 	-- execute IJMP instruction
	CUS_EXEC_RJMP, 	-- execute RJMP instruction
	CUS_EXEC_SBRS_1, 	-- execute SBRS instruction
	CUS_EXEC_SBRS_2,  --  (handle bit test result)
	CUS_EXEC_SBRS_3	--  (skip next instruction)
);

signal s_state: ControlUnitState;

begin

-- combinational logic

o_reset <= '1' when s_state = CUS_RESET
			else '0';

o_mode12K <= "00" when (s_state = CUS_FETCH_1 or s_state = CUS_EXEC_SBRS_3)
			else "10" when s_state = CUS_EXEC_RJMP
			else "XX";
			
o_modeAddZA <= "00" when (s_state = CUS_FETCH_1 or s_state = CUS_EXEC_RJMP or s_state = CUS_EXEC_SBRS_3)
			else "10" when s_state = CUS_EXEC_IJMP
			else "XX";
			
o_modePCZ <= '0'; -- unused at the moment because we don't fetch data from PM
--'0' when (s_state = CUS_FETCH or s_state = CUS_RESET_0 or s_state = CUS_RESET_1)
--			else '1';
			
o_loadPC <= '1' when (s_state = CUS_FETCH_1 or s_state = CUS_EXEC_IJMP or s_state = CUS_EXEC_RJMP or s_state = CUS_EXEC_SBRS_3)
			else '0' when (s_state = CUS_DECODE or s_state = CUS_EXEC_SBRS_1 or s_state = CUS_EXEC_SBRS_2)
			else 'X';

o_loadIR <= '1' when s_state = CUS_FETCH_2
			else '0';
			
-- data path

o_K <= unsigned(resize(signed(i_IR(11 downto 0)), 16)) when s_state = CUS_EXEC_RJMP
			else "XXXXXXXXXXXXXXXX";

-- synchronous logic

process (i_clk)
begin
	if rising_edge(i_clk) then
		if i_reset = '1' then
			s_state <= CUS_RESET;
		else
			case s_state is
				when CUS_RESET =>
					s_state <= CUS_FETCH_1;
					
				when CUS_FETCH_1 =>
					s_state <= CUS_FETCH_2;
				when CUS_FETCH_2 =>
					s_state <= CUS_DECODE;

				when CUS_DECODE =>
					case i_IR(15 downto 12) is
						when "1001" =>
							s_state <= CUS_EXEC_IJMP;
						when "1100" => 
							s_state <= CUS_EXEC_RJMP;
						when "1111" =>
							s_state <= CUS_EXEC_SBRS_1;
						when others =>
							s_state <= CUS_FETCH_1; -- skip unknown instructions for now
					end case;
							
				when CUS_EXEC_IJMP =>
					s_state <= CUS_FETCH_1;

				when CUS_EXEC_RJMP =>
					s_state <= CUS_FETCH_1;

				when CUS_EXEC_SBRS_1 =>
					s_state <= CUS_EXEC_SBRS_2;
				when CUS_EXEC_SBRS_2 =>
					if i_ALU_Z = '1' then -- bit not set, don't skip
						s_state <= CUS_FETCH_1;
					else -- bit set, skip instruction
						s_state <= CUS_EXEC_SBRS_3;
					end if;
				when CUS_EXEC_SBRS_3 =>
						s_state <= CUS_FETCH_1;
				
				when others =>
					s_state <= CUS_RESET;
			end case;
			
		end if;
	end if;
end process;

end Behavioral;
