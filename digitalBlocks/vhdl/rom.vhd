library ieee;
use ieee.std_logic_1164.all;


entity rom is
    port (
        adr: in std_logic_vector(1 downto 0);
        dout: out std_logic_vector(2 downto 0)
    );
end entity;

architecture rtl of rom is

begin

    process (adr)
    begin
        case adr is
            when "00" => dout <= "011";
            when "01" => dout <= "110";
            when "10" => dout <= "100";
            when "11" => dout <= "010";
        end case;        
    end process;

end architecture;