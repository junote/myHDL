library ieee;
use ieee.std_logic_1164.all;

entity sillyfunction is
  port (
    a, b, c : in std_logic;
    y       : out std_logic;

  );
end entity sillyfunction;

architecture rtl of sillyfunction is

begin

  y <= ((not a) and (not b) and (not c))or
    (a and (not b) and (not c))or
    (a and (not b) and c);
    
end architecture;