library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD_UNSIGNED.all;

use ieee.numeric_std.all;

entity decoder is
  generic (N : integer := 3);
  port (
    a : in std_logic_vector(N-1 downto 0);
    y : out std_logic_vector(2**N - 1 downto 0));
end;
architecture synth of decoder is
begin
  process (a)
  begin
    y                <= (others => '0');
    y(TO_INTEGER(signed(a))) <= '1';
  end process;
end;