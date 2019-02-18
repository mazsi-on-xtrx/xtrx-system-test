-------------------------------------------------------------------------------
-- Title      : minimal top level for xtrx
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top.vhd
-- Author     : mazsi-on-xtrx <@>
-- Company    : 
-- Created    : 2019-01-10
-- Last update: 2019-02-31
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2019 GPLv2 (no later versions)
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Author  Description
-- 2019-01-10  mazsi   Created
-- 2019-02-18  mazsi   cleaned up
-- 2019-02-31  mazsi   add power init sequencer
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;





entity top is

  port (
    ---------------------------------------------------------------------------
    PWRNRST    : out   std_logic := '1';
    SDA0, SCL0 : inout std_logic := '1';
    SDA1, SCL1 : inout std_logic := '1';
    ---------------------------------------------------------------------------
    SYSLED     : out   std_logic
   ---------------------------------------------------------------------------
    );

end top;





architecture imp of top is

  signal arstn, clk : std_logic;
  signal c          : unsigned(24 downto 0) := (others => '0');

  signal localrst            : std_logic := '1';
  signal i2cbusy, i2cok      : std_logic;
  signal sda0t, sda0i, scl0t : std_logic;
  signal sda1t, sda1i, scl1t : std_logic;

begin



  -----------------------------------------------------------------------------
  -- map pins to functions
  -----------------------------------------------------------------------------

  arstn <= '1';

  --  sysclkbuf : IBUFG port map(I => SYS_CLK, O => clk);

  SYSLED <= c(21) when i2cbusy = '1' else
            '0'   when (i2cbusy = '0' and i2cok = '0') else
            '1';





  -----------------------------------------------------------------------------
  -- use internal 65 MHz clock from startup module instead of an external clock
  -----------------------------------------------------------------------------

  startup : STARTUPE2
    generic map(
      PROG_USR      => "FALSE",
      SIM_CCLK_FREQ => 0.0
      )
    port map(
      CFGCLK    => open,
      CFGMCLK   => clk,                 -- ~65MHz internal clocl output
      EOS       => open,
      PREQ      => open,
      CLK       => '0',
      GSR       => '0',
      GTS       => '0',
      KEYCLEARB => '1',
      PACK      => '0',
      USRCCLKO  => '0',
      USRCCLKTS => '0',
      USRDONEO  => '1',  -- can't do fun - DONE is not connected to a LED on xtrx
      USRDONETS => '0'
      );





  -----------------------------------------------------------------------------
  -- simple counter
  -----------------------------------------------------------------------------

  c <= c + 1 when rising_edge(clk);





  -----------------------------------------------------------------------------
  -- power init sequencer: PMICL is on i2c bus #0, PMICF is on i2c bus #1
  -----------------------------------------------------------------------------

  localrst <= (localrst and not c(7)) when rising_edge(CLK);

  sda0i <= SDA0;
  sda1i <= SDA1;

  powerinit : entity work.xtrxinit generic map (CLKFREQ => 100_000_000, I2CFREQ => 1_000_000)
    port map (
      CLK   => clk, RST => localrst, BUSY => i2cbusy, OK => i2cok,
      SDA0T => sda0t, SDA0I => sda0i, SCL0T => scl0t,
      SDA1T => sda1t, SDA1I => sda1i, SCL1T => scl1t
      );

  SDA0 <= '0' when sda0t = '0' else 'Z';
  SCL0 <= '0' when scl0t = '0' else 'Z';

  SDA1 <= '0' when sda1t = '0' else 'Z';
  SCL1 <= '0' when scl1t = '0' else 'Z';



end imp;



