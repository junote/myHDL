library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity flop is
  port (
    clk : in std_logic;
    d   : in std_logic_vector(3 downto 0);
    q   : out std_logic_vector(3 downto 0));
end;

architecture synth of flop is
begin
  process (clk) begin
    if rising_edge(clk) then
      q <= d;
    end if;
  end process;
end;

architecture rtl of flop is

begin

  process (clk) begin
    if clk'event and clk = '1' then
      q <= d;
    end if;
  end process;

end architecture;