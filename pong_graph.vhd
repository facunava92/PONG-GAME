----------------------------------------------------------------------------------
-- Module Name:    pong_graph - arch 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity pong_graph is
	port(
			clk, reset				:			std_logic;
			btn						:			std_logic_vector(1 downto 0);
			pixel_x, pixel_y		:	in 	std_logic_vector(10 downto 0);
			gra_still				:	in 	std_logic;
			graph_on, hit, miss	: 	out 	std_logic;
			graph_rgb				:	out	std_logic_vector(2 downto 0)
			);
end pong_graph;

architecture arch of pong_graph is

--=============================================================================
-- Senal para el refresco de ball y paddle
--=============================================================================
signal refr_tick	:	std_logic;

--=============================================================================
-- x,y COORDENADAS DE (0,0) A (799,599) (Display region)
--=============================================================================
signal pix_x, pix_y :	unsigned(10 downto 0);
constant MAX_X	: integer := 800;
constant MAX_Y : integer := 600;

--=============================================================================
-- CONSTANTS
--=============================================================================
--wall width 
constant WALL_WIDTH	:	integer	:= 10;
constant TEXT_WIDTH	:	integer	:= 50;


-----------------------------------------------------------------------------
-- vertical walls
-----------------------------------------------------------------------------
-- left wall
-- right boundary of left wall
constant wall_LEFT_t_b : integer	:= TEXT_WIDTH-1;
constant wall_LEFT_r_b : integer := WALL_WIDTH;

--right wall
-- left boundary of left wall
constant wall_RIGHT_t_b : integer := TEXT_WIDTH-1;
constant wall_RIGHT_l_b : integer := MAX_X-WALL_WIDTH-2;

-----------------------------------------------------------------------------
-- horizontal walls
-----------------------------------------------------------------------------
-- bottom, left and right boundaries

constant wall_UP_t_b	: integer := TEXT_WIDTH-1;
constant wall_UP_b_b	: integer := wall_UP_t_b+WALL_WIDTH;

-----------------------------------------------------------------------------
-- paddle(con movimiento)
-----------------------------------------------------------------------------
--velocidad cuando se presiona un boton;
constant paddle_V	:	integer	:=	4;
constant PADDLE_SIZE : integer := 72;
constant PADDLE_CENTER : integer := (MAX_X-PADDLE_SIZE)/2;

--up boundary of paddle
constant paddle_y_t_b : integer := MAX_Y-WALL_WIDTH-1;

-- Right and Left variable boundaries
signal paddle_x_l_b, paddle_x_r_b	:	unsigned(10 downto 0);

--Registros
signal paddle_x_reg, paddle_x_next	:	unsigned(10 downto 0);



-----------------------------------------------------------------------------
-- round ball
-----------------------------------------------------------------------------
constant BALL_SIZE	: integer:=16; -- 16
constant BALL_V_Pos	:	unsigned (10 downto 0) := to_unsigned(5,11);
constant BALL_V_Neg	:	unsigned (10 downto 0) := unsigned(to_signed(-5,11));

-- ball left, right boundary
signal ball_x_l, ball_x_r: unsigned(10 downto 0);

-- ball top, bottom boundary
signal ball_y_t, ball_y_b: unsigned(10 downto 0);

--Registros de posicion de ball , se descompone en x , y
signal ball_x_reg, ball_x_next	:	unsigned(10 downto 0);
signal ball_y_reg, ball_y_next	:	unsigned(10 downto 0);

--Registros de velocidad de ball , se descompone en x , y
signal delta_x_reg, delta_x_next	:	unsigned(10 downto 0);
signal delta_y_reg, delta_y_next	:	unsigned(10 downto 0);


	----------------------------------------------
   -- round ball image ROM
   ----------------------------------------------
   type rom_type is array (0 to 15) of std_logic_vector(0 to 15);
   -- ROM definition
    constant BALL_ROM: rom_type :=
    (
        "0000011111100000",
        "0001110101011000",
        "0010000010101100",
        "0110000000010110",
        "0100000001010110",
        "1000000000010011",
        "1000000000101111",
        "1000000000010101",
        "1000000001010011",
        "1010100001010111",
        "1010101010111011",
        "0101010101001010",
        "0111010111110110",
        "0011101101011100",
        "0001111011111000",
        "0000011111100000"
    );
   signal rom_addr, rom_col: 	unsigned(3 downto 0);	--16 elementos ; 2^4 = 16
   signal rom_data			: 	std_logic_vector(15 downto 0);
   signal rom_bit				: 	std_logic;
	
-----------------------------------------------------------------------------
-- state signals of objects
-----------------------------------------------------------------------------
signal rd_ball_on									:	std_logic;
signal wall_on, paddle_on, sq_ball_on 		: std_logic;
signal wall_rgb, paddle_rgb, ball_rgb 		: std_logic_vector (2 downto 0);

--=============================================================================

------------------------------------------------------------
-- 	R		||		G		||		B		||		Color
------------------------------------------------------------
-- 	0		||		0		||		0		||		Negro
-- 	0		||		0		||		1		||		Azul
-- 	0		||		1		||		0		||		Verde
-- 	0		||		1		||		1		||		Cyan (Celeste)
-- 	1		||		0		||		0		||		Rojo
-- 	1		||		0		||		1		||		Magenta (Violeta)
-- 	1		||		1		||		0		||		Amarillo
-- 	1		||		1		||		1		||		Blanco (Gris)



begin

--=======================================================================================================
-- Asignacion de Registros
--=======================================================================================================
   process (clk,reset)
   begin
      if reset='1' then
         paddle_x_reg	<= (others=>'0');
         ball_x_reg 		<= (others=>'0');
         ball_y_reg 		<= (others=>'0');
         delta_x_reg 	<= ("00000000101");	--velocity 4
         delta_y_reg 	<= ("00000000101");  --velocity 4
      elsif (clk'event and clk='1') then
         paddle_x_reg 	<= paddle_x_next;
         ball_x_reg 		<= ball_x_next;
         ball_y_reg 		<= ball_y_next;
         delta_x_reg 	<= delta_x_next;
         delta_y_reg 	<= delta_y_next;
      end if;
	end process;
pix_x <= unsigned(pixel_x);
pix_y <= unsigned(pixel_y);

--=============================================================================
-- SIGNAL DE REFRESCO (1 vez cada inicio de Pantalla /72Hz/)
--=============================================================================
refr_tick <= '1' when (pix_y = MAX_y + 1) and (pix_x = 0) else
				 '0';

--=======================================================================================================
-- SIGNALS OF OBJECTS
--=======================================================================================================
-- WALL Circuit Generation (signals and rgb output) 
---------------------------------------------------------------------------------------------------------

wall_on <= 
				'1' when (pix_x <= wall_LEFT_r_b) and (wall_LEFT_t_b<=pix_y) else 
				'1' when (wall_RIGHT_l_b<= pix_x) and (wall_RIGHT_t_b<=pix_y)	else 
				'1' when (pix_y <= wall_UP_b_b) and (wall_UP_t_b<=pix_y) else
				'0';
wall_rgb <= "111"; --blanco;

----------------------------------------------------------------------------------------------------------
-- PADDLE Circuit Generation (signals and rgb output) 
----------------------------------------------------------------------------------------------------------
-- Boundaries(fronteras)
paddle_x_l_b <= paddle_x_reg;
paddle_x_r_b <= paddle_x_l_b + PADDLE_SIZE-1;

--Pixel dentro de Paddle
paddle_on <= 
					'1' when (paddle_x_l_b <= pix_x) and (pix_x <= paddle_x_r_b) 
						  and (paddle_y_t_b <= pix_y)	else
					'0';
paddle_rgb <= "011";		--cyan


--NUEVA POSICION EN EJE X
process(paddle_x_r_b, paddle_x_l_b, paddle_x_reg, refr_tick, btn, gra_still)
begin
	paddle_x_next <= paddle_x_reg;	--buffer, no move
	if(gra_still = '1')	then
	paddle_x_next <= to_unsigned(PADDLE_CENTER,11);
	elsif (refr_tick = '1') then
		if btn(1) = '1' and paddle_x_r_b < (wall_RIGHT_l_b - paddle_V) then
			paddle_x_next	<= paddle_x_reg + paddle_V ;
		elsif btn(0) = '1' and paddle_x_l_b > paddle_V then
			paddle_x_next <= paddle_x_reg - paddle_V;
		end if;
	end if;
end process;

----------------------------------------------------------------------------------------------------------
-- ROUND BALL Circuit Generation (signals and rgb output) 
----------------------------------------------------------------------------------------------------------
--boundaries (fronteras)
ball_x_l <= ball_x_reg;
ball_y_t <= ball_y_reg;
ball_x_r <= ball_x_l + BALL_SIZE - 1;
ball_y_b <= ball_y_t + BALL_SIZE - 1;

--Pixel dentro del rango de BALL_SIZE
-------------------------------------------------------------------------------------------------------
sq_ball_on <=
				'1' when (ball_x_l<=pix_x) and (pix_x<=ball_x_r) and	(ball_y_t<=pix_y) and (pix_y<=ball_y_b) else
				'0';
				
--Mapea el correspondiente pixel con la posicion de fila(address) y columna(col) dentro de la ROM
-------------------------------------------------------------------------------------------------------
rom_addr <= pix_y(3 downto 0) - ball_y_t(3 downto 0);
rom_col 	<= pix_x(3 downto 0) - ball_x_l(3 downto 0);

rom_data <= BALL_ROM(to_integer(rom_addr));
rom_bit <= rom_data(to_integer(rom_col));

rd_ball_on <=
					'1' when (sq_ball_on = '1') and (rom_bit = '1') else
					'0';
					
ball_rgb <= "100";  -- rojo

-- Nueva Posicion
--------------------------------------------------------------------------------------------------------
ball_x_next <= 
					to_unsigned((MAX_X)/2,11) when gra_still='1'	else
					ball_x_reg + delta_x_reg when refr_tick='1' 	else
               ball_x_reg ;
ball_y_next <= 
					to_unsigned((MAX_Y)/2,10) when gra_still='1' else
					ball_y_reg + delta_y_reg when refr_tick='1' 	else
               ball_y_reg ;

-- Nueva Velocidad (Direccion)
--------------------------------------------------------------------------------------------------------
process(	delta_x_reg, delta_y_reg, 
			ball_y_t, ball_y_b, ball_x_l, ball_x_r,
			paddle_x_l_b,paddle_x_r_b,
			gra_still, refr_tick)
begin
   hit <='0';
   miss <='0';
	delta_x_next <= delta_x_reg;			--buffers
	delta_y_next <= delta_y_reg;
	
	if gra_still='1' then            	--initial velocity
		delta_x_next <= BALL_V_Neg;
		delta_y_next <= BALL_V_Neg;
	elsif (ball_y_t <= wall_UP_b_b) then 			--reach upper wall
			delta_y_next <= BALL_V_Pos;
		elsif (wall_RIGHT_l_b <= ball_x_r) 	then	--reach right wall
			delta_x_next <= BALL_V_Neg;
		elsif (ball_x_l <= wall_LEFT_r_b )	then	--reach left wall
			delta_x_next <= BALL_V_Pos;
		elsif (paddle_x_l_b <= ball_x_r) and (ball_x_l <= paddle_x_r_b) then
			if ((paddle_y_t_b <= ball_y_b) and (ball_y_b <= MAX_Y-1)) then	
				if((refr_tick = '1')) then
					delta_y_next <= BALL_V_Neg;
					hit <= '1';
				end if;
			end if;
		elsif (ball_y_b>MAX_Y) then     	  -- reach bottom
				miss <= '1';                 -- a miss
	end if;
end process;
--=======================================================================================================
-- CIRCUITO MULTIPLEXOR DE ELEMENTOS
--=======================================================================================================

process(wall_on,paddle_on,rd_ball_on,wall_rgb, paddle_rgb, ball_rgb)

begin
   if wall_on='1' then
		graph_rgb <= wall_rgb;
		
		elsif paddle_on='1' then
			graph_rgb <= paddle_rgb;
				
			elsif rd_ball_on='1' then
				graph_rgb <= ball_rgb;	
	else
		graph_rgb <= "000"; -- negro
   end if;
end process;

   graph_on <= wall_on or paddle_on or rd_ball_on;

end arch;

