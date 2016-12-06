----------------------------------------------------------------------------------
-- Module Name:    pong_text - arch 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity pong_text is
port(
      clk, reset: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(10 downto 0);
		dig0, dig1, dig2: in std_logic_vector(3 downto 0);
      ball: in std_logic_vector(1 downto 0);
      text_on: out std_logic_vector(3 downto 0);
      text_rgb: out std_logic_vector(2 downto 0)
   );
end pong_text;

architecture arch of pong_text is
	signal pix_x, pix_y	: 	unsigned(10 downto 0);
	signal rom_addr		: 	std_logic_vector(10 downto 0);
	signal font_word		: 	std_logic_vector(7 downto 0);
	
	signal char_addr	: std_logic_vector(6 downto 0);
   signal row_addr	: std_logic_vector(3 downto 0);
   signal bit_addr	: std_logic_vector(2 downto 0);
	
	signal char_addr_s	: std_logic_vector(6 downto 0);
   signal row_addr_s		: std_logic_vector(3 downto 0);
   signal bit_addr_s		: std_logic_vector(2 downto 0);	
	signal score_on		:	std_logic;
	
	signal char_addr_l	: std_logic_vector(6 downto 0);
   signal row_addr_l		: std_logic_vector(3 downto 0);
   signal bit_addr_l		: std_logic_vector(2 downto 0);	
	signal logo_on			: std_logic;
	
	signal char_addr_r	: std_logic_vector(6 downto 0);
   signal row_addr_r		: std_logic_vector(3 downto 0);
   signal bit_addr_r		: std_logic_vector(2 downto 0);
	signal rule_rom_addr: unsigned(6 downto 0);	
	signal rule_on			: std_logic;
	
	signal char_addr_o	: std_logic_vector(6 downto 0);
   signal row_addr_o		: std_logic_vector(3 downto 0);
   signal bit_addr_o		: std_logic_vector(2 downto 0);	
	signal over_on			: std_logic;
	
	signal font_bit		: 	std_logic;
	
	
	type rule_rom_type is array (0 to 127) of std_logic_vector (6 downto 0);
	 constant RULE_ROM: rule_rom_type :=
   (
      -- fila 1
      "1001001", -- x49	I
      "1101110", -- x6e	n
      "1110011", -- x73	s
      "1110100", -- x74	t
      "1110010", -- x72	r
      "1110101", -- x75 u
      "1100011", -- x63 c
      "1100011", -- x63 c
      "1101001", -- x69 i
      "1101111", -- x6f o
      "1101110", -- x6e n
      "1100101", -- x65 e
      "1110011", -- x73 s
      "0111010", -- x3a :
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		
		 -- fila 2
      "1010000", -- x50	P
      "1110010", -- x72	r
      "1100101", -- x65 e
      "1110011", -- x73 s
      "1101001", -- x69 i
      "1101111", -- x6f o
      "1101110", -- x6e n
      "1100101", -- x65 e
      "0000000",
      "1110101", -- x75 u
      "1101110", -- x6e	n
      "0000000",
      "1100010", -- x62 b
      "1101111", -- x6f o
      "1110100", -- x74	t
      "1101111", -- x6f o
      "1101110", -- x6e n
		"0000000",
		"1110000", -- x70 p
		"1100001", -- x61 a
		"1110010", -- x72	r
		"1100001", -- x61 a
		"0000000",
		"0000000",
		"1100011", -- x63 c
		"1101111", -- x6f o
		"1101101", -- x6d	m
		"1100101", -- x65 e
      "1101110", -- x6e n 
		"1111010", -- x7a z
      "1100001", -- x61 a
      "1110010", -- x72	r
		
		 -- fila 3
      "1111001", -- x79	y
      "0000000",
		"1110000", -- x70 p
		"1100001", -- x61 a
		"1110010", -- x72	r
		"1100001", -- x61 a
		"0000000",
		"1101101", -- x6d	m
      "1101111", -- x6f o
      "1110110", -- x76 v
      "1100101", -- x65 e
      "1110010", -- x72	r
      "0000000",
      "1101100", -- x6c l
      "1100001", -- x61 a
      "0000000",
      "1110000", -- x70 p
      "1101100", -- x6c l 
      "1100001", -- x61 a
      "1110100", -- x74	t
      "1100001", -- x61 a
      "1100110", -- x66 f
      "1101111", -- x6f o
		"1110010", -- x72	r
		"1101101", -- x6d	m
		"1100001", -- x61 a		
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",

		 -- fila 3
		"0000000",
		"0000000",
      "0000000",
		"0000000",
      "0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"1100010", -- x62 b
      "1110101", -- x75 u
      "1100101", -- x65 e
      "1101110", -- x6e n
      "1100001", -- x61 a
      "0000000",
      "0000000",
      "1110011", -- x73 s
      "1110101", -- x75 u
      "1100101", -- x65 e
      "1110010", -- x72	r
      "1110100", -- x74	t
      "1100101", -- x65 e
      "0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000",
		"0000000"
   );
	
begin
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
	
--=================================================================
-- INSTANCIACIONES
--=================================================================
--CHAR_ROM con los caracteres.
-------------------------------------------------------------------
char_unit: entity work.char_ROM
	port map
	(	clk=>clk,
		addr=>rom_addr,
		data=>font_word
	);
-------------------------------------------------------------------
--#################################################################
--###################  ESTRUCTURAS GRAFICAS  ######################
--#################################################################
--=================================================================
--	 * PUNTAJE
--  - Puntaje de 3 digitos con la cantidad de bolas disponibles
--		en el borde superior izquierdo
--  - Escala de 16 x 32
--  - 20 chars: "Puntaje:XXX Bolas:X"
--=================================================================
   score_on <=
      '1' when pix_y(10 downto 5)=0 and
               pix_x(10 downto 4)<20 else
      '0';
		
   row_addr_s <= std_logic_vector(pix_y(4 downto 1));	--filas 16
   bit_addr_s <= std_logic_vector(pix_x(3 downto 1));	--col 8
	with pix_x(8 downto 4) select
	char_addr_s <=
        "1010000" 	when "00000", -- P x50
        "1110101" 	when "00001", -- u x75
        "1101110" 	when "00010", -- n x6e
        "1110100" 	when "00011", -- t x74
        "1100001" 	when "00100", -- a x61
		  "1101010" 	when "00101", -- j x6a
		  "1100101" 	when "00110", -- e x65
        "0111010" 	when "00111", -- : x3a
		  "011"&dig2	when "01000", -- digit 100
        "011"&dig1	when "01001", -- digit 10
        "011"&dig0 	when "01010", -- digit 1
        "0000000" 	when "01011",
        "0000000" 	when "01100",
        "1000010"		when "01101", -- B x42
        "1101111" 	when "01110", -- o x6f
        "1101100" 	when "01111", -- l x6c
        "1100001" 	when "10000", -- a x61
		  "1110011" 	when "10001", -- s x73
        "0111010" 	when "10010", -- : x3a
        "01100"&ball when others;

--=================================================================
--	 * LOGO
--  - Se observa el logo al fondo del juego
--  - Escala de 64 x 128
--=================================================================
   logo_on <=
      '1' when pix_y(10 downto 7)=2 and
               (4<=pix_x(10 downto 6) and pix_x(10 downto 6)<=8) else
      '0';
		
   bit_addr_l <= std_logic_vector(pix_x(5 downto 3));	-- 64
	row_addr_l <= std_logic_vector(pix_y(6 downto 3));	-- 128
	with pix_x(9 downto 6) select
	char_addr_l <=
        "1010101" 	when "0100", -- U x55
        "1010100" 	when "0110", -- T x54
        "1001110" 	when "1000", -- N x4e	
		  "0000000"   when others;  
		  
--=================================================================
--	 * REGLAS
--  - 4 Lineas, 32 Caracters.
--  - Escala de 8 x 16
--  - Texto : 
--					Instrucciones:
--					Incline el celular para
--					mover la plataforma.Presione
--					la bateria para comenzar
--=================================================================

   rule_on <= '1' when pix_x(10 downto 8) = "00001" and
                       pix_y(10 downto 6)=  "00010"  else
              '0';
   bit_addr_r <= std_logic_vector(pix_x(2 downto 0));	-- 8
	row_addr_r <= std_logic_vector(pix_y(3 downto 0));	-- 16
   rule_rom_addr <= pix_y(5 downto 4) & pix_x(7 downto 3); --2bit= filas ; 5bit=caracteres
   char_addr_r <= RULE_ROM(to_integer(rule_rom_addr));
	
--=================================================================
--	 * GAME OVER
--  - Se muestra "Game Over" en el centro
--  - Escala de 32 x 64
-- - 9 Caracters
--=================================================================
   over_on <=
					'1' when pix_y(10 downto 6) = 7 and
								8<= pix_x(10 downto 5) and pix_x(10 downto 5)<=16 else
					'0';
   bit_addr_o <= std_logic_vector(pix_x(4 downto 2));
	row_addr_o <= std_logic_vector(pix_y(5 downto 2));
   with pix_x(9 downto 5) select
	char_addr_o <=
	  "1000111" when "01000", -- G x47
	  "1100001" when "01001", -- a x61
	  "1101101" when "01010", -- m x6d
	  "1100101" when "01011", -- e x65
	  "0000000" when "01100", --
	  "1001111" when "01101", -- O x4f
	  "1110110" when "01110", -- v x76
	  "1100101" when "01111", -- e x65
	  "1110010" when others; -- r x72
	 
-------------------------------------------------------------------
--#################################################################
--##############  MUX de DIRECCIONES A LA ROM  ####################
--#################################################################
--=================================================================
-------------------------------------------------------------------
-- 	R		||		G		||		B		||		Color
-------------------------------------------------------------------
-- 	0		||		0		||		0		||		Negro
-- 	0		||		0		||		1		||		Azul
-- 	0		||		1		||		0		||		Verde
-- 	0		||		1		||		1		||		Cyan (Celeste)
-- 	1		||		0		||		0		||		Rojo
-- 	1		||		0		||		1		||		Magenta (Violeta)
-- 	1		||		1		||		0		||		Amarillo
-- 	1		||		1		||		1		||		Blanco (Gris)
---------------------------------------------------------------------

   process(score_on,logo_on,rule_on,pix_x,pix_y,font_bit,
           char_addr_s,char_addr_l,char_addr_r,char_addr_o,
           row_addr_s,row_addr_l,row_addr_r,row_addr_o,
           bit_addr_s,bit_addr_l,bit_addr_r,bit_addr_o)
   begin
      text_rgb <= "000";  				--background, black
      if score_on='1' then
         char_addr <= char_addr_s;
         row_addr <= row_addr_s;
         bit_addr <= bit_addr_s;
         if font_bit='1' then
            text_rgb <= "110";		--score, blue
         end if;
      elsif rule_on='1' then
         char_addr <= char_addr_r;
         row_addr <= row_addr_r;
         bit_addr <= bit_addr_r;
         if font_bit='1' then
            text_rgb <= "101";		--rule, yellow
         end if;
			
		elsif logo_on = '1' then
		char_addr <= char_addr_l;
		row_addr <= row_addr_l;
		bit_addr <= bit_addr_l;
		if font_bit='1' then
			text_rgb <= "111";
		end if;		--logo, white


      else				
		char_addr <= char_addr_o;
		row_addr <= row_addr_o;
		bit_addr <= bit_addr_o;
		if font_bit='1' then
		text_rgb <= "100";		--game over, red
		end if;
	

      end if;
   end process;
   text_on <= score_on & logo_on & rule_on & over_on;


--=================================================================
-- char_ROM INTERFAZ
--=================================================================
rom_addr <= char_addr & row_addr;
font_bit <= font_word(to_integer(unsigned(not bit_addr)));

end arch;

