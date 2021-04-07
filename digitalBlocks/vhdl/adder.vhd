library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity adder is
  generic (N : integer := 8);
  port (
    a, b : in std_logic_vector(N - 1 downto 0);
    cin  : in std_logic;
    s    : out std_logic_vector(N - 1 downto 0);
    cout : out std_logic);
end;

architecture synth of adder is
  signal result : std_logic_vector(N downto 0);
begin
  result <= ('0' & a) + ('0' & b) + cin;
  s <= result(N-1 downto 0);
  cout   <= result(N);
end;