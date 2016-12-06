----------------------------------------------------------------------------------
-- Module Name:    m1000_counter - arch 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity m1000_counter is
port(
     clk, reset		: in std_logic;
     d_inc, d_clr		: in std_logic;
     dig0,dig1,dig2	: out std_logic_vector (3 downto 0)
   );
end m1000_counter;

architecture arch of m1000_counter is
   signal dig0_reg, dig1_reg, dig2_reg		: unsigned(3 downto 0);
   signal dig0_next,dig1_next,dig2_next	: unsigned(3 downto 0);
begin

-- registers
process (clk,reset)
begin
	if reset='1' then
		dig2_reg <= (others=>'0');
      dig1_reg <= (others=>'0');
      dig0_reg <= (others=>'0');
      
	elsif (clk'event and clk='1') then
		dig2_reg <= dig2_next;
      dig1_reg <= dig1_next;
      dig0_reg <= dig0_next;
   end if;
end process;

   -- next-state logic for the decimal counter
process(d_clr,d_inc,dig2_reg,dig1_reg,dig0_reg)
begin
	dig0_next <= dig0_reg;
   dig1_next <= dig1_reg;
   dig2_next <= dig2_reg;

	if (d_clr='1') then
		dig0_next <= (others=>'0');
      dig1_next <= (others=>'0');
		dig2_next <= (others=>'0');

   elsif (d_inc='1') then
		if dig0_reg = 9 then
			dig0_next <= (others=>'0');
			if dig1_reg=9 then 
				dig1_next <= (others=>'0');
				if dig2_reg=9 then
					dig2_next <= (others=>'0');
				else
					dig2_next <= dig2_reg + 1;
				end if;
			else
				dig1_next <= dig1_reg + 1;
			end if;
		else 
			dig0_next <= dig0_reg + 1;
      end if;
   end if;
	
end process;

dig0 <= std_logic_vector(dig0_reg);
dig1 <= std_logic_vector(dig1_reg);
dig2 <= std_logic_vector(dig2_reg);

end arch;


