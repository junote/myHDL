library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity subtractor is
  generic (N : integer := 8);
  port (
    a, b : in std_logic_vector(N - 1 downto 0);
   y    : out std_logic_vector(N - 1 downto 0));
end;

architecture synth of subtractor is
begin
  y <= a - b;
end;