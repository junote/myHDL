library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity fulladder is
  port (
    a, b, cin : in std_logic;
    s, cout   : out std_logic);
end;

architecture synth of fulladder is
begin
  process (a, b, cin)
    variable p, g : std_logic;
  begin
    p := a xor b;
    --blocking
    g := a and b;
    -- blocking
    s    <= p xor cin;
    cout <= g or (p and cin);
  end process;
end;