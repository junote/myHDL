library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity bitwiz is
  port (
    c : in std_logic_vector(2 downto 0);
    d : in std_logic_vector(2 downto 0);
    y : out std_logic_vector(8 downto 0)
  );
end entity bitwiz;

architecture rtls of bitwiz is
begin

  y <= c(2 downto 1) & d(0) & d(0) & d(0) & c(0) & "101";

end architecture;