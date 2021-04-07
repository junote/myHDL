library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity shiftreg is
  generic (
    N : integer := 8
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;
    load  : in std_logic;
    sin   : in std_logic;
    d     : in std_logic_vector(N - 1 downto 0);
    q     : buffer std_logic_vector(N - 1 downto 0);
    sout  : out std_logic
  );
end entity;
architecture rtl of shiftreg is

begin

  process (clk, reset)
  begin
    if reset = '1' then
      q <= (others => '0');
    elsif rising_edge(clk) then
      if load = '1' then
        q      <= d;
      else q <= q(N - 2 downto 0) & sin;
      end if;
    end if;
  end process;

  sout <= q(N - 1);

end architecture;