-------------------------------------------------------------------------------
-- Title      : minimal top level for xtrx
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top.vhd
-- Author     : mazsi-on-xtrx <@>
-- Company    : 
-- Created    : 2019-01-10
-- Last update: 2019-02-18
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
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;





entity top is

  port (
    ---------------------------------------------------------------------------
    SYSLED : out std_logic
   ---------------------------------------------------------------------------
    );

end top;





architecture imp of top is

  signal arstn, clk : std_logic;
  signal c          : unsigned(24 downto 0) := (others => '0');

begin



  -----------------------------------------------------------------------------
  -- map pins to functions
  -----------------------------------------------------------------------------

  arstn <= '1';

  --  sysclkbuf : IBUFG port map(I => SYS_CLK, O => clk);

  SYSLED <= c(21);





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



end imp;



