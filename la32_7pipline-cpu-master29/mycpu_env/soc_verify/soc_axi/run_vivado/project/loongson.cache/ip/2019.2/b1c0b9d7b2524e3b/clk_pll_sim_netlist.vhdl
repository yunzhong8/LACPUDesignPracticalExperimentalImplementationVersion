-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
-- Date        : Thu Jul 20 18:19:44 2023
-- Host        : nb running 64-bit Ubuntu 22.04.2 LTS
-- Command     : write_vhdl -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
--               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ clk_pll_sim_netlist.vhdl
-- Design      : clk_pll
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xc7a200tfbg676-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_clk_pll_clk_wiz is
  port (
    cpu_clk : out STD_LOGIC;
    sys_clk : out STD_LOGIC;
    clk_60 : out STD_LOGIC;
    clk_70 : out STD_LOGIC;
    clk_80 : out STD_LOGIC;
    clk_90 : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );
end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_clk_pll_clk_wiz;

architecture STRUCTURE of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_clk_pll_clk_wiz is
  signal clk_60_clk_pll : STD_LOGIC;
  signal clk_70_clk_pll : STD_LOGIC;
  signal clk_80_clk_pll : STD_LOGIC;
  signal clk_90_clk_pll : STD_LOGIC;
  signal clk_in1_clk_pll : STD_LOGIC;
  signal clkfbout_buf_clk_pll : STD_LOGIC;
  signal clkfbout_clk_pll : STD_LOGIC;
  signal cpu_clk_clk_pll : STD_LOGIC;
  signal sys_clk_clk_pll : STD_LOGIC;
  signal NLW_plle2_adv_inst_DRDY_UNCONNECTED : STD_LOGIC;
  signal NLW_plle2_adv_inst_LOCKED_UNCONNECTED : STD_LOGIC;
  signal NLW_plle2_adv_inst_DO_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  attribute BOX_TYPE : string;
  attribute BOX_TYPE of clkf_buf : label is "PRIMITIVE";
  attribute BOX_TYPE of clkin1_ibufg : label is "PRIMITIVE";
  attribute CAPACITANCE : string;
  attribute CAPACITANCE of clkin1_ibufg : label is "DONT_CARE";
  attribute IBUF_DELAY_VALUE : string;
  attribute IBUF_DELAY_VALUE of clkin1_ibufg : label is "0";
  attribute IFD_DELAY_VALUE : string;
  attribute IFD_DELAY_VALUE of clkin1_ibufg : label is "AUTO";
  attribute BOX_TYPE of clkout1_buf : label is "PRIMITIVE";
  attribute BOX_TYPE of clkout2_buf : label is "PRIMITIVE";
  attribute BOX_TYPE of clkout3_buf : label is "PRIMITIVE";
  attribute BOX_TYPE of clkout4_buf : label is "PRIMITIVE";
  attribute BOX_TYPE of clkout5_buf : label is "PRIMITIVE";
  attribute BOX_TYPE of clkout6_buf : label is "PRIMITIVE";
  attribute BOX_TYPE of plle2_adv_inst : label is "PRIMITIVE";
begin
clkf_buf: unisim.vcomponents.BUFG
     port map (
      I => clkfbout_clk_pll,
      O => clkfbout_buf_clk_pll
    );
clkin1_ibufg: unisim.vcomponents.IBUF
    generic map(
      IOSTANDARD => "DEFAULT"
    )
        port map (
      I => clk_in1,
      O => clk_in1_clk_pll
    );
clkout1_buf: unisim.vcomponents.BUFG
     port map (
      I => cpu_clk_clk_pll,
      O => cpu_clk
    );
clkout2_buf: unisim.vcomponents.BUFG
     port map (
      I => sys_clk_clk_pll,
      O => sys_clk
    );
clkout3_buf: unisim.vcomponents.BUFG
     port map (
      I => clk_60_clk_pll,
      O => clk_60
    );
clkout4_buf: unisim.vcomponents.BUFG
     port map (
      I => clk_70_clk_pll,
      O => clk_70
    );
clkout5_buf: unisim.vcomponents.BUFG
     port map (
      I => clk_80_clk_pll,
      O => clk_80
    );
clkout6_buf: unisim.vcomponents.BUFG
     port map (
      I => clk_90_clk_pll,
      O => clk_90
    );
plle2_adv_inst: unisim.vcomponents.PLLE2_ADV
    generic map(
      BANDWIDTH => "OPTIMIZED",
      CLKFBOUT_MULT => 11,
      CLKFBOUT_PHASE => 0.000000,
      CLKIN1_PERIOD => 10.000000,
      CLKIN2_PERIOD => 0.000000,
      CLKOUT0_DIVIDE => 13,
      CLKOUT0_DUTY_CYCLE => 0.500000,
      CLKOUT0_PHASE => 0.000000,
      CLKOUT1_DIVIDE => 11,
      CLKOUT1_DUTY_CYCLE => 0.500000,
      CLKOUT1_PHASE => 0.000000,
      CLKOUT2_DIVIDE => 18,
      CLKOUT2_DUTY_CYCLE => 0.500000,
      CLKOUT2_PHASE => 0.000000,
      CLKOUT3_DIVIDE => 16,
      CLKOUT3_DUTY_CYCLE => 0.500000,
      CLKOUT3_PHASE => 0.000000,
      CLKOUT4_DIVIDE => 14,
      CLKOUT4_DUTY_CYCLE => 0.500000,
      CLKOUT4_PHASE => 0.000000,
      CLKOUT5_DIVIDE => 12,
      CLKOUT5_DUTY_CYCLE => 0.500000,
      CLKOUT5_PHASE => 0.000000,
      COMPENSATION => "ZHOLD",
      DIVCLK_DIVIDE => 1,
      IS_CLKINSEL_INVERTED => '0',
      IS_PWRDWN_INVERTED => '0',
      IS_RST_INVERTED => '0',
      REF_JITTER1 => 0.010000,
      REF_JITTER2 => 0.010000,
      STARTUP_WAIT => "FALSE"
    )
        port map (
      CLKFBIN => clkfbout_buf_clk_pll,
      CLKFBOUT => clkfbout_clk_pll,
      CLKIN1 => clk_in1_clk_pll,
      CLKIN2 => '0',
      CLKINSEL => '1',
      CLKOUT0 => cpu_clk_clk_pll,
      CLKOUT1 => sys_clk_clk_pll,
      CLKOUT2 => clk_60_clk_pll,
      CLKOUT3 => clk_70_clk_pll,
      CLKOUT4 => clk_80_clk_pll,
      CLKOUT5 => clk_90_clk_pll,
      DADDR(6 downto 0) => B"0000000",
      DCLK => '0',
      DEN => '0',
      DI(15 downto 0) => B"0000000000000000",
      DO(15 downto 0) => NLW_plle2_adv_inst_DO_UNCONNECTED(15 downto 0),
      DRDY => NLW_plle2_adv_inst_DRDY_UNCONNECTED,
      DWE => '0',
      LOCKED => NLW_plle2_adv_inst_LOCKED_UNCONNECTED,
      PWRDWN => '0',
      RST => '0'
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  port (
    cpu_clk : out STD_LOGIC;
    sys_clk : out STD_LOGIC;
    clk_60 : out STD_LOGIC;
    clk_70 : out STD_LOGIC;
    clk_80 : out STD_LOGIC;
    clk_90 : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix : entity is true;
end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix;

architecture STRUCTURE of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
begin
inst: entity work.decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_clk_pll_clk_wiz
     port map (
      clk_60 => clk_60,
      clk_70 => clk_70,
      clk_80 => clk_80,
      clk_90 => clk_90,
      clk_in1 => clk_in1,
      cpu_clk => cpu_clk,
      sys_clk => sys_clk
    );
end STRUCTURE;
