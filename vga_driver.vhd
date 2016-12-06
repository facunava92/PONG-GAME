----------------------------------------------------------------------------------
-- Module Name:    vga_driver - sync 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_driver is
	port(
			clk, reset			:	in 	std_logic;
			hsync,	vsync		:	out	std_logic;
			video_on, p_tick	:	out	std_logic;
			pixel_x, pixel_y	:	out	std_logic_vector(10 downto 0)
	);
end vga_driver;

--||-----------------------------------------------------------------------------------------||
--||    	Para		|| Display	||   Front		||		Back		|| 	Sync		||		Total	 		||
--||		72Hz		||				||	  Porch  	||		Porch		|| 	Pulse		||		Pixeles		||
--||-----------------------------------------------------------------------------------------||
--||  Horizontal	||		800	||		56			||		 64		||		120		||		 1040			||
--||-----------------------------------------------------------------------------------------||
--||	Vertical		||		600	||		37			||		 23		||		6		  	||		 666			||
--||/////////////////////////////////////////////////////////////////////////////////////////||

architecture sync of vga_driver is
	----------------VGA 800x600 sync parameters-------------
	--------------------------------------------------------	
	------------------ Horizontal --------------------------
	constant HD: integer := 800; -- horizontal display area
   constant HF: integer := 56;  -- h. front porch
   constant HB: integer := 64;  -- h. back porch
   constant HR: integer := 120;  -- h. sync
	------------------ Vertical ----------------------------
   constant VD: integer := 600; -- vertical display area
   constant VF: integer := 37;  -- v. front porch
   constant VB: integer := 23;  -- v. back porch
   constant VR: integer := 6;   -- v. sync
	--------------------------------------------------------

    -- 50Mhz clock
    signal mod1_reg	: 	std_logic;

    -- sync counters (for the horizontal and vertical scans)
    signal v_count_reg, v_count_next	: unsigned(10 downto 0);
    signal h_count_reg, h_count_next	: unsigned(10 downto 0);

    -- output buffer (to remove potential glitches)
    signal v_sync_reg, h_sync_reg	: std_logic;
    signal v_sync_next, h_sync_next	: std_logic;

    -- status signal
	signal h_end, v_end : std_logic;
	
begin
	--registers
   process(clk, reset)
   begin
		if reset = '1' then
			mod1_reg <= '0';
         v_count_reg <= (others => '0');
         h_count_reg <= (others => '0');
         v_sync_reg 	<= '0';
         h_sync_reg 	<= '0';
		elsif clk'event and clk = '1' then
			mod1_reg <= '1';
         v_count_reg <= v_count_next;
         h_count_reg <= h_count_next;
         v_sync_reg 	<= v_sync_next;
         h_sync_reg 	<= h_sync_next;
		end if;
	end process;

	--status
   h_end <= -- end of horizontal counter 0-1039 
		'1' when h_count_reg = (HD + HF + HB + HR - 1) else 
		'0';
   v_end <=	-- end of horizontal counter 0-665 
		'1' when v_count_reg = (VD + VF + VB + VR - 1) else 
		'0';
--=============================================================================
-- mod-1040 horizontal sync counter
--=============================================================================
   process(h_count_reg, h_end, mod1_reg)
   begin
		if mod1_reg = '1'	then 		--	50MHz
			if h_end = '1' then
				h_count_next <= (others => '0');
         else
				h_count_next <= h_count_reg + 1;
         end if;
		else
			h_count_next <= h_count_reg;
      end if;
	end process;

--=============================================================================
-- mod-666 vertical sync counter
--=============================================================================
    process(v_count_reg, h_end, v_end, mod1_reg)
    begin
			if mod1_reg = '1'	and h_end='1' then 		--	50MHz
				if (v_end = '1') then
					v_count_next <= (others => '0');
				else
					v_count_next <= v_count_reg + 1;
         end if;
		else
            v_count_next <= v_count_reg;
      end if;
	end process;
--=============================================================================
-- horizontal and vertical sync, buffered to avoid glitch
--=============================================================================

    h_sync_next <= 
		'1' when (h_count_reg >= (HD + HF))						--656
			  and (h_count_reg <= (HD + HF + HR - 1)) else	--751
      '0';
    v_sync_next <= 
		'1' when (v_count_reg >= (VD + VF)) 					--490
			  and (v_count_reg <= (VD + VF + VR - 1)) else	--491
      '0';
--=============================================================================
-- video on/off
--=============================================================================
    video_on <= 
		'1' when (h_count_reg < HD) and (v_count_reg < VD) else 
		'0';
--=============================================================================
-- Senal de salida para instaciacion
--=============================================================================
    hsync 	<= h_sync_reg;
    vsync 	<= v_sync_reg;
    pixel_x <= std_logic_vector(h_count_reg);
    pixel_y <= std_logic_vector(v_count_reg);
	 p_tick	<=	mod1_reg;
end sync;


