library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity testbench1 is -- no inputs or outputs
end;
architecture sim of testbench1 is
  component sillyfunction
    port (
      a, b, c : in std_logic;
      y       : out std_logic);
  end component;
  signal a, b, c, y : std_logic;
begin
--   instantiate device under test
  dut : sillyfunction port map(a, b, c, y);
--   apply inputs one at a time
  process begin
    a <= '0';
    b <= '0';
    c <= '0';
    wait for 10 ns;
    c <= '1';
    wait for 10 ns;
    b <= '1';
    c <= '0';
    wait for 10 ns;
    c <= '1';
    wait for 10 ns;
    a <= '1';
    b <= '0';
    c <= '0';
    wait for 10 ns;
    c <= '1';
    wait for 10 ns;
    b <= '1';
    c <= '0';
    wait for 10 ns;
    c <= '1';
    wait for 10 ns;
    wait;
    -- wait forever
  end process;
end;