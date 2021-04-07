library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity flopr is
  port (
    clk, reset : in std_logic;
    d          : in std_logic_vector(3 downto 0);
    q          : out std_logic_vector(3 downto 0));
end;

architecture asynchronous of flopr is
begin
  process (clk, reset) begin
    if reset = '1' then
      q <= "0000";
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;
end;


library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity flopr is
  port (
    clk, reset : in std_logic;
    d          : in std_logic_vector(3 downto 0);
    q          : out std_logic_vector(3 downto 0));
end;

architecture synchronous of flopr is
begin
  process (clk) begin
    if rising_edge(clk) then
      if reset = '1' then
        q      <= "0000";
      else q <= d;
      end if;
    end if;
  end process;
end;