-------------------------------------------------------------------------------
-- Title      : low level uart interface
-- Project    : 
-------------------------------------------------------------------------------
-- File       : thinuart.vhd
-- Author     : mazsi-on-xtrx <@>
-- Company    : 
-- Created    : 2014-08-12
-- Last update: 2019-04-30
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Author  Description
-- 2014-08-12  mazsi   Created
-- ..
-- 2019-04-30  mazsi   stripped most of debuguartlite module
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;








entity thinuart is

  generic (
    CLKFREQ  : positive := 50_000_000;
    BAUDRATE : positive := 115200;
    RXWIDTH  : positive := 16;
    TXWIDTH  : positive := 16
    );

  port (
    ---------------------------------------------------------------------------
    CLK   : in  std_logic;
    RST   : in  std_logic                              := '0';
    ---------------------------------------------------------------------------
    RX    : in  std_logic                              := '0';
    TX    : out std_logic;
    ---------------------------------------------------------------------------
    START : in  std_logic                              := '0';
    BUSY  : out std_logic;
    D     : in  std_logic_vector(TXWIDTH - 1 downto 0) := (others => '0');
    --
    DONE  : out std_logic;
    Q     : out std_logic_vector(RXWIDTH - 1 downto 0)
   ---------------------------------------------------------------------------
    );

end entity thinuart;








architecture imp of thinuart is

  constant BAUDDIV : integer := CLKFREQ / BAUDRATE / 8;



  signal bauden, biten, niben : std_logic;

  signal txpos : std_logic_vector(TXWIDTH/8 downto 0);
  signal txbuf : std_logic_vector(TXWIDTH - 1 downto 0);
  signal txten : std_logic_vector(9 downto 0);  -- with start + stop char

  signal rxpipe                : std_logic_vector(79 downto 0);
  signal rxten, rxconst        : std_logic_vector(9 downto 0);  -- with start + stop char
  signal rxok, rxdone, rxdone1 : std_logic;
  signal rxbuf                 : std_logic_vector(RXWIDTH - 1 downto 0);

begin



  -----------------------------------------------------------------------------
  -- cascaded dividers: baud8 tick (/BAUDDIV), bit tick (/8), nibble tick (/10)
  -----------------------------------------------------------------------------

  process (CLK) is
    function iszero (val : in integer) return std_logic is
    begin
      if val = 0 then return '1'; else return '0'; end if;
    end;

    function nextval (val, limit : in integer; en, rst : in std_logic) return integer is
    begin
      if en = '0' then return val;
      elsif rst = '1' then return limit - 1;
      else return val - 1; end if;
    end;

    variable counterl                                 : integer range 0 to BAUDDIV - 1;
    variable counterm                                 : integer range 0 to 7;
    variable counterh                                 : integer range 0 to 9;
    variable tmpl0, tmpl1, tmpl2, tmpm1, tmpm2, tmph2 : std_logic;
  begin
    if CLK'event and CLK = '1' then
      -- align all of them to the same clk cycle
      niben  <= tmph2 and tmpm2 and tmpl2;
      biten  <= tmpm2 and tmpl2; tmpm2 := tmpm1;
      bauden <= tmpl2; tmpl2 := tmpl1; tmpl1 := tmpl0;

      -- divide by 10
      tmph2    := iszero(counterh);
      counterh := nextval(counterh, 10, tmpl1 and tmpm1, tmph2);

      -- divide by 8
      tmpm1    := iszero(counterm);
      counterm := nextval(counterm, 8, tmpl0, tmpm1);

      -- divide by BAUDDIV
      tmpl0    := iszero(counterl);
      counterl := nextval(counterl, BAUDDIV, '1', tmpl0);
    end if;
  end process;





  -----------------------------------------------------------------------------
  -- tx: go nibble by nibble, bit by bit (including start & stop for 8N1)
  -----------------------------------------------------------------------------

  process (CLK, txbuf, txpos, txten) is
    variable tmpout : std_logic_vector(7 downto 0);
  begin

    -- nibble by nibble
    if CLK'event and CLK = '1' then
      if RST = '1' then
        txpos <= (others => '0');
        txbuf <= (others => '0');
      elsif txpos(txpos'left) = '0' and START = '1' then  -- save incomig D(ata)
        txpos <= (others => '1');
        txbuf <= D;
      elsif txpos(txpos'left) = '1' and niben = '1' then  -- next char
        txpos <= txpos(txpos'left - 1 downto 0) & "0";
        txbuf <= txbuf(txbuf'left - 8 downto 0) & "00000000";
      end if;
    end if;

    -- no base 16 encoding
    tmpout := txbuf(txbuf'left downto txbuf'left - 7);

    -- bit by bit
    if CLK'event and CLK = '1' then
      if RST = '1' then
        txten <= (others => '1');
      elsif txpos(txpos'left) = '1' and niben = '1' then  -- load next char
        txten <= "1" & tmpout & "0";
      elsif biten = '1' then                              -- next bit
        txten <= "1" & txten(txten'left downto 1);
      end if;
    end if;

    -- final output
    BUSY <= txpos(txpos'left);
    TX   <= txten(0);

  end process;





  -----------------------------------------------------------------------------
  -- rx: shift in data, pattern match, base16 decode, shift nibbles
  -- calculation is pipelined, we have many (BAUDDIV) clock cycles to complete.
  -----------------------------------------------------------------------------

  process (CLK, rxdone, rxbuf) is
    function isconst (a : in std_logic_vector) return std_logic is  -- returns '1' if all bits are either '1' or '0'
    begin
      return and_reduce(a) or not or_reduce(a);
    end;

    variable cnt    : std_logic_vector(7 downto 0);
    variable tmpout : std_logic_vector(7 downto 0);
  begin
    if CLK'event and CLK = '1' then

      -- shift in data
      if bauden = '1' then
        rxpipe <= RX & rxpipe(rxpipe'left downto 1);
      end if;

      -- try to locate the 10 bits: check that bits are stable for at least 5 (out of 8) divs
      -- also, pick one of the bits (doesn't matter which one, it will only be used if all 5 are the same)
      for i in rxten'range loop
        rxconst(i) <= isconst(rxpipe(8 * i + 4 downto 8 * i));
        rxten(i)   <= rxpipe(8 * i);
      end loop;  -- i

      -- check framing, stable data, no received character recently
      rxok <= (rxten(9) and not rxten(0)) and and_reduce(rxconst) and not or_reduce(cnt);

      -- inhibit any new incoming character for ~75 bauden ticks
      if cnt = 0 and rxok = '1' and bauden = '1' then
        cnt := x"4b";
      elsif cnt /= 0 and bauden = '1' then
        cnt := cnt - 1;
      end if;

      -- no base16 decoding
      tmpout := rxten(8 downto 1);

      -- accumulate incoming bytes
      if RST = '1' then
        rxbuf <= (others => '0');
      elsif bauden = '1' and rxok = '1' then
        rxbuf <= rxbuf(rxbuf'left - 8 downto rxbuf'right) & tmpout;
      end if;

      rxdone  <= rxok;
      rxdone1 <= rxdone;                -- to generate 1 clk pulse on output

    end if;

    -- final output
    DONE <= rxdone and not rxdone1;
    Q    <= rxbuf;

  end process;



end architecture imp;

