library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity counter is
  generic (
    N : integer := 8
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;
    q     : buffer std_logic_vector(N - 1 downto 0)
  );
end entity counter;

architecture rtl of counter is

begin

  process (clk, reset)
  begin
    if reset = '1' then
      q <= ((others => '0'));
    elsif rising_edge(clk) then
      q <= q + '1';
    end if;
  end process;

end architecture;