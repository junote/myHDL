library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity priorityckt is
  port (
    a : in std_logic_vector(3 downto 0);
    y : out std_logic_vector(3 downto 0));
end;
architecture synth of priorityckt is
begin
  process (a) begin
    if a(3) = '1' then
      y <= "1000";
    elsif a(2) = '1' then
      y <= "0100";
    elsif a(1) = '1' then
      y <= "0010";
    elsif a(0) = '1' then
      y      <= "0001";
    else y <= "0000";
    end if;
  end process;
end;