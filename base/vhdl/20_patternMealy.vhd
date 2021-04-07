library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity patternMealy is
  port (
    clk, reset : in std_logic;
    a          : in std_logic;
    y          : out std_logic);
end;
architecture synth of patternMealy is
  type statetype is (S0, S1);
  signal state, nextstate : statetype;
begin
  -- state register
  process (clk, reset) begin
    if reset = '1' then
      state <= S0;
    elsif rising_edge(clk) then
      state <= nextstate;
    end if;
  end process;
--   next state logic
  process (a,state) begin
    case state is
      when S0 =>
        if a = '1' then
          nextstate      <= S0;
        else nextstate <= S1;
        end if;
      when S1 =>
        if a = '1' then
          nextstate      <= S0;
        else nextstate <= S1;
        end if;
      when others =>
        nextstate <= S0;
    end case;
  end process;
--   output logic
  y <= '1' when (a = '1' and state = S1) else '0';
end;