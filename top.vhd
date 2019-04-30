-------------------------------------------------------------------------------
-- Title      : minimal top level for xtrx
-- Project    : 
-------------------------------------------------------------------------------
-- File       : top.vhd
-- Author     : mazsi-on-xtrx <@>
-- Company    : 
-- Created    : 2019-01-10
-- Last update: 2019-03-05
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
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;





entity top is

  port (
    ---------------------------------------------------------------------------
    SDA0, SCL0 : inout std_logic := '1';
    SDA1, SCL1 : inout std_logic := '1';
    ---------------------------------------------------------------------------
    GPIO       : inout std_logic_vector(11 downto 0);
    ---------------------------------------------------------------------------
    GPS1PPS    : in    std_logic;
    GPSTX      : in    std_logic;
    GPSRX      : out   std_logic := '1';
    ---------------------------------------------------------------------------
    CLK026EN   : out   std_logic := '1';
    CLK026SEL  : out   std_logic := '0';
    CLK026IN   : in    std_logic;
    ---------------------------------------------------------------------------
    USBREF026  : out   std_logic;
    USBNRST    : out   std_logic := '1';
    USBCLK     : in    std_logic := '1';
    USBSTP     : out   std_logic;
    USBDIR     : in    std_logic;
    USBNXT     : in    std_logic;
    USBD       : inout std_logic_vector(7 downto 0);
    ---------------------------------------------------------------------------
    LMSNRST    : out   std_logic;
    SS1        : out   std_logic;
    SCK1       : out   std_logic;
    MOSI1      : out   std_logic;
    MISO1      : in    std_logic;
    ---------------------------------------------------------------------------
    PCIECLKP   : in    std_logic;
    PCIECLKN   : in    std_logic;
    PCIETXP    : out   std_logic_vector(0 downto 0);
    PCIETXN    : out   std_logic_vector(0 downto 0);
    PCIERXP    : in    std_logic_vector(0 downto 0);
    PCIERXN    : in    std_logic_vector(0 downto 0);
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

  signal spiout, spiin, spiinsav : std_logic_vector(31 downto 0) := (others => '0');
  signal ssi, scki, mosii, misoi : std_logic;
  signal sckfallen, spiok        : std_logic;

begin



  -----------------------------------------------------------------------------
  -- map pins to functions
  -----------------------------------------------------------------------------

  arstn <= '1';

  --  sysclkbuf : IBUFG port map(I => SYS_CLK, O => clk);

  SYSLED <= c(21) when i2cbusy = '1' else
            '0'   when (i2cbusy = '0' and i2cok = '0') else
            c(22) when spiok = '0' else
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





  -----------------------------------------------------------------------------
  -- SPI interface: query RF chip version / revision / mask from reg 0x002f
  -----------------------------------------------------------------------------

  LMSNRST <= not (i2cbusy or not i2cok);  -- keep reset pulled until after power sequence had completed

  misoi <= MISO1;

  process (clk) is
    constant SPIADDR : std_logic_vector(31 downto 16) := x"002F";  -- reg address
    constant SPIVAL  : std_logic_vector(15 downto 0)  := "0011100001000001";  -- expected val
  begin
    if clk'event and clk = '1' then

      spiout <= SPIADDR & x"0000";

      ssi   <= c(8) and c(7);
      scki  <= not c(8) and c(7) and c(1);
      mosii <= spiout(to_integer(not c(6 downto 2)));

      sckfallen <= not c(8) and c(7) and c(1) and c(0);

      if sckfallen = '1' then
        spiin <= spiin(30 downto 0) & misoi;
      end if;

      if c(8 downto 0) = "101111111" then
        spiinsav <= spiin;
      end if;

      spiok <= and_reduce(spiinsav(SPIVAL'range) xnor SPIVAL);

    end if;
  end process;

  SS1   <= ssi;
  SCK1  <= scki;
  MOSI1 <= mosii;





  -----------------------------------------------------------------------------
  -- pcie endpoint
  -----------------------------------------------------------------------------

  pcie : entity work.xilinx_pcie_2_1_ep_7x
    port map (
      pci_exp_txp => PCIETXP,
      pci_exp_txn => PCIETXN,
      pci_exp_rxp => PCIERXP,
      pci_exp_rxn => PCIERXN,
      sys_clk_p   => PCIECLKP,
      sys_clk_n   => PCIECLKN,
      sys_rst_n   => '1'
      );



end imp;



