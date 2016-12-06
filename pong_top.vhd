----------------------------------------------------------------------------------
-- Module Name:    pong_top - pong_top_arch 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pong_top is
   port (
      clk,reset		: 	in 	std_logic;
		btn				:	in 	std_logic_vector(1 downto 0);
      hsync, vsync	: 	out 	std_logic;
      red, green		: 	out 	std_logic_vector(2 downto 0);
		blue				:	out	std_logic_vector(1 downto 0);
		sseg				:	out	std_logic_vector(0 to 6);
      an					: 	out 	std_logic_vector(3 downto 0);
		buzzer			:	out 	std_logic
   );
end pong_top;

architecture pong_top_arch of pong_top is

   type state_type is (newgame, play, newball, over);
   signal state_reg, state_next: state_type;

   signal pixel_x, pixel_y			:	std_logic_vector (10 downto 0);
	signal video_on, pixel_tick	: 	std_logic;

	signal text_on						: 	std_logic_vector(3 downto 0);
   signal text_rgb					: 	std_logic_vector(2 downto 0);
	
	signal graph_rgb					: 	std_logic_vector(2 downto 0);
	signal graph_on, gra_still		:	std_logic;
	signal hit, miss					: 	std_logic;
	
   signal rgb_reg, rgb_next		: 	std_logic_vector(2 downto 0);
	
	signal dig0, dig1, dig2			: 	std_logic_vector(3 downto 0);
   signal d_inc, d_clr				: std_logic;

	signal ball							: 	std_logic_vector(1 downto 0);
	signal ball_reg, ball_next		: 	unsigned(1 downto 0);
	
	signal timer_tick, timer_start, timer_up: std_logic;


begin

--####################################################################
--########################	 INSTANCIACIONES ##########################
--####################################################################																							
--=================================================================	
--  								VGA_DRIVER											
--=================================================================	
   vga_driver_unit: entity work.vga_driver									
      port map(clk=>clk, 
					reset=>reset,
               video_on=>video_on, 
					p_tick=>pixel_tick,
               hsync=>hsync, 
					vsync=>vsync,
               pixel_x=>pixel_x, 
					pixel_y=>pixel_y
					);
--=================================================================
-- 							UNIDAD GRAFICA
--=================================================================
   pong_graph_unit: entity work.pong_graph(arch)
      port map (clk=>clk,
					reset=>reset,
					btn=>btn,
               pixel_x=>pixel_x, 
					pixel_y=>pixel_y,
					hit=>hit, 
					miss=>miss,
					gra_still=>gra_still,
					graph_on=>graph_on,
               graph_rgb=>graph_rgb);

--=================================================================
-- 							UNIDAD DE TEXTO
--=================================================================
   ball <= std_logic_vector(ball_reg);  --type conversion
   text_unit: entity work.pong_text
      port map(clk=>clk, 
					reset=>reset,
               pixel_x=>pixel_x, 
					pixel_y=>pixel_y,
               dig0=>dig0, 
					dig1=>dig1,
					dig2=>dig2,
					ball=>ball,
               text_on=>text_on, 
					text_rgb=>text_rgb
					);
					
--=================================================================
-- 							TEMPORIZADOR 2 SEGUNDOS
--=================================================================
   timer_tick <=  -- 72 Hz tick
      '1' when pixel_x="00000000000" and
               pixel_y="00000000000" else
      '0';
   timer_unit: entity work.timer
      port map(clk=>clk, 
					reset=>reset,
               timer_tick=>timer_tick,
               timer_start=>timer_start,
               timer_up=>timer_up);
					
--=================================================================
-- 						CONTADOR DE 3 DIGITOS , |1000|
--=================================================================
   counter_unit: entity work.m1000_counter
      port map(clk=>clk,
					reset=>reset,
               d_inc=>d_inc, 
					d_clr=>d_clr,
               dig0=>dig0, 
					dig1=>dig1,
					dig2=>dig2
					);
					
--=================================================================
-- 						DRIVER 7 SEGMENTOS
--=================================================================
   sseg_unit: entity work.sseg_mux
      port map(clk=>clk,
					reset=>reset,
					in2=>dig2,
               in1=>dig1, 
					in0=>dig0,
					sseg=>sseg,
					an	=>an
					);
					
--=================================================================
-- 						SONIDO BUZZER
--=================================================================					
	sound_unit:entity work.sound_play(arch)
		port map(clk => clk,
					reset => reset,
					hit_sound => hit, 
					miss_sound => miss,
					buzzer => buzzer
					);
					
--####################################################################


--####################################################################
--###########################	 REGISTROS #############################
--####################################################################		
process (clk,reset)
	begin
      if reset='1' then
         state_reg <= newgame;
         ball_reg <= (others=>'0');
         rgb_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
         ball_reg <= ball_next;
         if (pixel_tick='1') then
           rgb_reg <= rgb_next;
         end if;
      end if;
   end process;
--####################################################################


--####################################################################
--#############################	 FSM  ###############################
--####################################################################	
process(btn,hit,miss,timer_up,state_reg,ball_reg,ball_next)
begin
	gra_still <= '1';
	timer_start <='0';
	d_inc <= '0';
	d_clr <= '0';
	state_next <= state_reg;
	ball_next <= ball_reg;
	
	case state_reg is
		when newgame =>
			ball_next <= "11";    -- Tres Bolas
			d_clr <= '1';         -- Resetea el Puntaje
			if (btn /= "00") then -- Espera el cambio en el pulsador
				state_next <= play;
				ball_next <= ball_reg - 1;
			end if;
			
		when play =>
			gra_still <= '0';    -- Cambio a Pantalla en Movimiento
			if hit='1' then
				d_inc <= '1';     -- Activa en 1 el puntaje
			elsif miss='1' then
				if (ball_reg=0) then
					state_next <= over;
				else
					state_next <= newball;
				end if;
				timer_start <= '1';  -- 2s timer
				ball_next <= ball_reg - 1;
			end if;
			
		when newball =>
			-- Se espera 2 seg. provenientes del estado "play"
			if  timer_up='1' and (btn /= "00") then -- Espera los 2 seg Y el cambio en el pulsador
			  state_next <= play;
			end if;
			
		when over =>
			-- Se espera 2 seg. provenientes del estado "play"
			if timer_up='1' then
				 state_next <= newgame;
			end if;
	 end case;
end process;
--####################################################################


--####################################################################
--###########################	 MUX RGB  ##############################
--####################################################################
process(state_reg,video_on,graph_on,graph_rgb,text_on,text_rgb)
begin
	if video_on='0' then
		rgb_next <= "000"; 		-- blank the edge/retrace
	else
		-- Multiplexor de puntaje, 
		if (text_on(3)='1') 									--PUNTAJE
			or	(state_reg=newgame and text_on(1)='1') --INSTRUCCIONES
			or	(state_reg=over 	 and text_on(0)='1') --GAME OVER
			then
			rgb_next <= text_rgb;
			
		elsif graph_on='1'  then 							--Muestra Graficos
		  rgb_next <= graph_rgb;
		  
		elsif text_on(2)='1'  then 						--Muestra Logo, Menor Prioridad
		  rgb_next <= text_rgb;
		else
		  rgb_next <= "000"; 								-- black background
		end if;
	end if;
end process;
--####################################################################	

	
red 	<= "111" when (rgb_reg(2) = '1' and video_on='1') else "000";
green <= "111" when (rgb_reg(1) = '1' and video_on='1') else "000";
blue 	<= "11" 	when (rgb_reg(0) = '1' and video_on='1') else "00";
	
end pong_top_arch;