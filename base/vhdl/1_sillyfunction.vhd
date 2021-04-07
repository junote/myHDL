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


/*
 VHDL code has three parts: the library use clause, the
 entity declaration, and the architecture body. The library
 use clause will be discussed in Section 4.7.2. The entity
 declaration lists the module name and its inputs and outputs.
 The architecture body defines what the module does
 VHDL signals, such as inputs and outputs, must have a
 type declaration. Digital signals should be declared to be
 STD_LOGIC type. STD_LOGIC signals can have a value of '0'
 or '1',  The STD_LOGIC type is defined in
 the IEEE.STD_LOGIC_1164 library, which is why the library
 must be used.

*/