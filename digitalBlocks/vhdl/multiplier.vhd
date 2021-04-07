library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity multiplier is
  generic (
    N : integer := 8
  );
  port (
    a, b : in std_logic_vector(N - 1 downto 0);
    y    : out std_logic_vector(2 * N - 1 downto 0)
  );
end entity multiplier;
architecture rtl of multiplier is

begin

  y <= a * b;

end architecture;