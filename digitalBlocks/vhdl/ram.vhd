library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
  generic (
    N : integer := 6;
    M : integer := 32
  );
  port (
    we   : in std_logic;
    clk  : in std_logic;
    adr  : in std_logic_vector(N - 1 downto 0);
    din  : in std_logic_vector(M - 1 downto 0);
    dout : out std_logic_vector(M - 1 downto 0)
  );
end entity;

architecture rtl of ram is
  type mem_array is array ((2 ** N - 1) downto 0) of std_logic_vector(M - 1 downto 0);
  signal mem : mem_array;
begin

  process (clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem(to_integer(unsigned(adr))) <= din;
      end if;
    end if;
  end process;

  dout <= mem(to_integer(unsigned(adr)));
end architecture;