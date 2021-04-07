library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity priority_casez is
  port (
    a : in std_logic_vector(3 downto 0);
    y : out std_logic_vector(3 downto 0));
end;
architecture dontcare of priority_casez is
begin
  process (a) begin
    case  a is
      when "1---" => y <= "1000";
      when "01--" => y <= "0100";
      when "001-" => y <= "0010";
      when "0001" => y <= "0001";
      when others => y <= "0000";
    end case;
  end process;
end;