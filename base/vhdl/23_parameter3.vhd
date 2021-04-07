library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity andN is
  generic (width : integer := 8);
  port (
    a : in std_logic_vector(width - 1 downto 0);
    y : out std_logic);
end;
architecture synth of andN is
  signal x : std_logic_vector(width - 1 downto 0);
begin
  x(0) <= a(0);
  gen : for i in 1 to width - 1 generate
    x(i) <= a(i) and x(i - 1);
  end generate;

  y<= x(width - 1);

end;