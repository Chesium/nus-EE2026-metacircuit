library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MouseDisplay is
port (
   pixel_clk: in std_logic;
   xpos     : in std_logic_vector(11 downto 0);
   ypos     : in std_logic_vector(11 downto 0);
   mouse_left: in std_logic;
   hcount   : in std_logic_vector(11 downto 0);
   vcount   : in std_logic_vector(11 downto 0);
   enable_mouse_display_out : out std_logic;
   red_out  : out std_logic_vector(3 downto 0);
   green_out: out std_logic_vector(3 downto 0);
   blue_out : out std_logic_vector(3 downto 0)
);

attribute rom_extract : string;
attribute rom_extract of MouseDisplay: entity is "yes";
attribute rom_style : string;
attribute rom_style of MouseDisplay: entity is "distributed";

end MouseDisplay;

architecture Behavioral of MouseDisplay is

-- Legacy 16x16 cursor implementation kept for reference.
-- type displayrom is array(0 to 255) of std_logic_vector(1 downto 0);
-- constant mouserom: displayrom := (
-- "00","00","11","11","11","11","11","11","11","11","11","11","11","11","11","11",
-- "00","01","00","11","11","11","11","11","11","11","11","11","11","11","11","11",
-- "00","01","01","00","11","11","11","11","11","11","11","11","11","11","11","11",
-- "00","01","01","01","00","11","11","11","11","11","11","11","11","11","11","11",
-- "00","01","01","01","01","00","11","11","11","11","11","11","11","11","11","11",
-- "00","01","01","01","01","01","00","11","11","11","11","11","11","11","11","11",
-- "00","01","01","01","01","01","01","00","11","11","11","11","11","11","11","11",
-- "00","01","01","01","01","01","01","01","00","11","11","11","11","11","11","11",
-- "00","01","01","01","01","01","00","00","00","00","11","11","11","11","11","11",
-- "00","01","01","01","01","01","00","11","11","11","11","11","11","11","11","11",
-- "00","01","00","00","01","01","00","11","11","11","11","11","11","11","11","11",
-- "00","00","11","11","00","01","01","00","11","11","11","11","11","11","11","11",
-- "00","11","11","11","00","01","01","00","11","11","11","11","11","11","11","11",
-- "11","11","11","11","11","00","01","01","00","11","11","11","11","11","11","11",
-- "11","11","11","11","11","00","01","01","00","11","11","11","11","11","11","11",
-- "11","11","11","11","11","11","00","00","11","11","11","11","11","11","11","11"
-- );
-- constant OFFSET: std_logic_vector(4 downto 0) := "10000";
-- signal xdiff_legacy: std_logic_vector(3 downto 0) := (others => '0');
-- signal ydiff_legacy: std_logic_vector(3 downto 0) := (others => '0');
--
-- x_diff_legacy: process(hcount, xpos)
-- variable temp_diff: std_logic_vector(11 downto 0) := (others => '0');
-- begin
--    temp_diff := hcount - xpos;
--    xdiff_legacy <= temp_diff(3 downto 0);
-- end process x_diff_legacy;
--
-- y_diff_legacy: process(vcount, ypos)
-- variable temp_diff: std_logic_vector(11 downto 0) := (others => '0');
-- begin
--    temp_diff := vcount - ypos;
--    ydiff_legacy <= temp_diff(3 downto 0);
-- end process y_diff_legacy;
--
-- mousepixel <= mouserom(conv_integer(ydiff_legacy & xdiff_legacy))
--               when rising_edge(pixel_clk);
--
-- enable_mouse_legacy: process(pixel_clk, hcount, vcount, xpos, ypos)
-- begin
--    if(rising_edge(pixel_clk)) then
--       if(hcount >= xpos + X"001" and hcount < (xpos + OFFSET - X"001") and
--          vcount >= ypos and vcount < (ypos + OFFSET) and
--          (mousepixel = "00" or mousepixel = "01")) then
--          enable_mouse_display <= '1';
--       else
--          enable_mouse_display <= '0';
--       end if;
--    end if;
-- end process enable_mouse_legacy;

function hover_row(row_idx: integer) return std_logic_vector is
begin
   case row_idx is
      when 0  => return "0000000000000000000000000000";
      when 1  => return "0000000000000000000000000000";
      when 2  => return "0000110000000000000000000000";
      when 3  => return "0011111000000000000000000000";
      when 4  => return "0011001100000000001000000000";
      when 5  => return "0011001100110111111110000000";
      when 6  => return "0001000111111111110110000000";
      when 7  => return "0001100111001100110011000000";
      when 8  => return "0000110011001100110001000000";
      when 9  => return "0000110011000110011001100000";
      when 10 => return "0000011001100110011000110000";
      when 11 => return "0000011000100011001000110000";
      when 12 => return "0000001100110000000000011000";
      when 13 => return "0000000100010000000000011000";
      when 14 => return "0000000110000000000000001100";
      when 15 => return "0000111110000000000000001100";
      when 16 => return "0001111111000000000000001100";
      when 17 => return "0011000011100000000000001100";
      when 18 => return "0001100001000000000000001100";
      when 19 => return "0000111000000000000000011000";
      when 20 => return "0000011100000000000000111000";
      when 21 => return "0000000110000000000001110000";
      when 22 => return "0000000011100000000111000000";
      when 23 => return "0000000001110000011110000000";
      when 24 => return "0000000000011111111000000000";
      when 25 => return "0000000000000111100000000000";
      when others => return "0000000000000000000000000000";
   end case;
end function;

function pressed_row(row_idx: integer) return std_logic_vector is
begin
   case row_idx is
      when 0  => return "0000000000000000000000000000";
      when 1  => return "0000000000000000000000000000";
      when 2  => return "0000000000000000000000000000";
      when 3  => return "0000000001100110111100000000";
      when 4  => return "0000000111111111110110000000";
      when 5  => return "0000011111001100110011000000";
      when 6  => return "0000110011001100110001000000";
      when 7  => return "0000110011000110011001100000";
      when 8  => return "0000011001100110011000110000";
      when 9  => return "0000011000100011001000110000";
      when 10 => return "0000001100110000000000011000";
      when 11 => return "0000111100010000000000011000";
      when 12 => return "0001101110000000000000001100";
      when 13 => return "0011001110000000000000001100";
      when 14 => return "0011001111000000000000001100";
      when 15 => return "0011000001100000000000001100";
      when 16 => return "0001100000100000000000001100";
      when 17 => return "0000111000000000000000011000";
      when 18 => return "0000011100000000000000111000";
      when 19 => return "0000000110000000000001110000";
      when 20 => return "0000000011100000000111000000";
      when 21 => return "0000000001110000011110000000";
      when 22 => return "0000000000011111111000000000";
      when 23 => return "0000000000000111100000000000";
      when 24 => return "0000000000000000000000000000";
      when 25 => return "0000000000000000000000000000";
      when others => return "0000000000000000000000000000";
   end case;
end function;

function pressed_fill_row(row_idx: integer) return std_logic_vector is
begin
   case row_idx is
      when 0  => return "0000000000000000000000000000";
      when 1  => return "0000000000000000000000000000";
      when 2  => return "0000000000000000000000000000";
      when 3  => return "0000000000000000000000000000";
      when 4  => return "0000000000000000001000000000";
      when 5  => return "0000000000110011001100000000";
      when 6  => return "0000001100110011001110000000";
      when 7  => return "0000001100111001100110000000";
      when 8  => return "0000000110011001100111000000";
      when 9  => return "0000000111011100110111000000";
      when 10 => return "0000000011001111111111100000";
      when 11 => return "0000000011101111111111100000";
      when 12 => return "0000010001111111111111110000";
      when 13 => return "0000110001111111111111110000";
      when 14 => return "0000110000111111111111110000";
      when 15 => return "0000111110011111111111110000";
      when 16 => return "0000011111011111111111110000";
      when 17 => return "0000000111111111111111100000";
      when 18 => return "0000000011111111111111000000";
      when 19 => return "0000000001111111111100000000";
      when 20 => return "0000000000011111111000000000";
      when 21 => return "0000000000001111100000000000";
      when 22 => return "0000000000000000000000000000";
      when 23 => return "0000000000000000000000000000";
      when 24 => return "0000000000000000000000000000";
      when 25 => return "0000000000000000000000000000";
      when others => return "0000000000000000000000000000";
   end case;
end function;

function fill_row(row_idx: integer) return std_logic_vector is
begin
   case row_idx is
      when 0  => return "0000000000000000000000000000";
      when 1  => return "0000000000000000000000000000";
      when 2  => return "0000000000000000000000000000";
      when 3  => return "0000000000000000000000000000";
      when 4  => return "0000110000000000000000000000";
      when 5  => return "0000110000000000000000000000";
      when 6  => return "0000111000000000001000000000";
      when 7  => return "0000011000110011001100000000";
      when 8  => return "0000001100110011001110000000";
      when 9  => return "0000001100111001100110000000";
      when 10 => return "0000000110011001100111000000";
      when 11 => return "0000000111011100110111000000";
      when 12 => return "0000000011001111111111100000";
      when 13 => return "0000000011101111111111100000";
      when 14 => return "0000000001111111111111110000";
      when 15 => return "0000000001111111111111110000";
      when 16 => return "0000000000111111111111110000";
      when 17 => return "0000111100011111111111110000";
      when 18 => return "0000011110111111111111110000";
      when 19 => return "0000000111111111111111100000";
      when 20 => return "0000000011111111111111000000";
      when 21 => return "0000000001111111111110000000";
      when 22 => return "0000000000011111111000000000";
      when 23 => return "0000000000001111100000000000";
      when others => return "0000000000000000000000000000";
   end case;
end function;

constant CURSOR_SIZE: std_logic_vector(11 downto 0) := conv_std_logic_vector(28, 12);

signal mousepixel: std_logic_vector(1 downto 0) := (others => '0');
signal enable_mouse_display: std_logic := '0';
signal xdiff: std_logic_vector(4 downto 0) := (others => '0');
signal ydiff: std_logic_vector(4 downto 0) := (others => '0');

begin

   x_diff: process(hcount, xpos)
   variable temp_diff: std_logic_vector(11 downto 0) := (others => '0');
   begin
      temp_diff := hcount - xpos;
      xdiff <= temp_diff(4 downto 0);
   end process x_diff;

   y_diff: process(vcount, ypos)
   variable temp_diff: std_logic_vector(11 downto 0) := (others => '0');
   begin
      temp_diff := vcount - ypos;
      ydiff <= temp_diff(4 downto 0);
   end process y_diff;

   read_mouse_pixel: process(pixel_clk)
   variable row_bits: std_logic_vector(27 downto 0);
   variable fill_bits: std_logic_vector(27 downto 0);
   variable pressed_fill_bits: std_logic_vector(27 downto 0);
   variable x_idx: integer;
   variable y_idx: integer;
   begin
      if(rising_edge(pixel_clk)) then
         x_idx := conv_integer(xdiff);
         y_idx := conv_integer(ydiff);
         if(x_idx < 28 and y_idx < 28) then
            if(mouse_left = '1') then
               row_bits := pressed_row(y_idx);
            else
               row_bits := hover_row(y_idx);
            end if;
            fill_bits := fill_row(y_idx);
            pressed_fill_bits := pressed_fill_row(y_idx);

            if(row_bits(27 - x_idx) = '1') then
               mousepixel <= "00";
            elsif(fill_bits(27 - x_idx) = '1' or (mouse_left = '1' and pressed_fill_bits(27 - x_idx) = '1')) then
               mousepixel <= "01";
            else
               mousepixel <= "11";
            end if;
         else
            mousepixel <= "11";
         end if;
      end if;
   end process read_mouse_pixel;

   enable_mouse: process(pixel_clk)
   begin
      if(rising_edge(pixel_clk)) then
         if(hcount >= xpos and hcount < (xpos + CURSOR_SIZE) and
            vcount >= ypos and vcount < (ypos + CURSOR_SIZE) and
            (mousepixel = "00" or mousepixel = "01")) then
            enable_mouse_display <= '1';
         else
            enable_mouse_display <= '0';
         end if;
      end if;
   end process enable_mouse;

   enable_mouse_display_out <= enable_mouse_display;

   process(pixel_clk)
   begin
      if(rising_edge(pixel_clk)) then
         if(enable_mouse_display = '1') then
            if(mousepixel = "01") then
               red_out <= (others => '1');
               green_out <= (others => '1');
               blue_out <= (others => '1');
            elsif(mousepixel = "00") then
               red_out <= (others => '0');
               green_out <= (others => '0');
               blue_out <= (others => '0');
            end if;
         end if;
      end if;
   end process;

end Behavioral;
