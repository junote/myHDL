library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity comparators is
  generic (
    N : integer := 8
  );
  port (
    a, b                      : in std_logic_vector(N - 1 downto 0);
    eq, neq, lt, lte, gt, gte : out std_logic

  );
end entity comparators;

architecture rtl of comparators is

begin

  eq  <= '1' when (a = b) else '0';
  neq <= '1' when (a /= b) else '0';
  lt  <= '1' when (a < b) else '0';
  lte <= '1' when (a <= b) else '0';
  gt  <= '1' when (a > b) else '0';
  gte <= '1' when (a >= b) else '0';

end architecture;