-- library IEEE;
-- use IEEE.STD_LOGIC_1164.all;

-- entity tristate is
--   port (
--     a  : in std_logic_vector(3 downto 0);
--     en : in std_logic;
--     y  : out std_logic_vector(3 downto 0));
-- end;

-- architecture synth of tristate is
-- begin
--   y <= a when en = '1' else "ZZZZ";
--   --   y <= a when en else "XXXX";
-- end;

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mux2 is
  port (
    d0, d1 : in std_logic_vector(3 downto 0);
    s      : in std_logic;
    y      : out std_logic_vector(3 downto 0));
end;
architecture struct of mux2 is
  component tristate
    port (
      a  : in std_logic_vector(3 downto 0);
      en : in std_logic;
      y  : out std_logic_vector(3 downto 0));
  end component;
  signal sbar : std_logic;
begin
  sbar <= not s;
  t0 : tristate port map(d0, sbar, y);
  t1 : tristate port map(d1, s, y);
end;

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mux2_8 is
  port (
    d0, d1 : in std_logic_vector(7 downto 0);
    s      : in std_logic;
    y      : out std_logic_vector(7 downto 0));
end;
architecture struct of mux2_8 is
  component mux2
    port (
      d0, d1 : in std_logic_vector(3 downto 0);
      s      : in std_logic;
      y      : out std_logic_vector(3 downto 0));
  end component;
begin
  lsbmux : mux2
  port map(
    d0(3 downto 0), d1(3 downto 0),
    s, y(3 downto 0));
  msbmux : mux2
  port map(
    d0(7 downto 4), d1(7 downto 4),
    s, y(7 downto 4));
end;