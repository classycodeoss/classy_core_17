library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Contains the program instructions
entity ProgramMemory is
port ( 
	i_clk:			in std_logic;
	i_addr:			in unsigned(15 downto 0);
	o_data:			out unsigned(15 downto 0)
);
end ProgramMemory;

architecture Behavioral of ProgramMemory is

type PROGMEM is array(7 downto 0) of unsigned(15 downto 0);

signal s_pm: PROGMEM := (
x"0000", -- unused
x"9409", -- ijmp
x"cfff", -- rjmp .-2
x"cfff", -- rjmp .-2
x"fe00", -- sbrs r0, 0
x"c003", -- rjmp .+6
x"0e2e", -- add r2,r30
x"e0e3"  -- ldi r30,3
);

begin

process (i_clk)
begin
	if rising_edge(i_clk) then
		o_data <= s_pm(to_integer(i_addr));
	end if;
end process;

end Behavioral;
