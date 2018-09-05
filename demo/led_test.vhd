library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity LedTest is
    port(
        LED0         : out std_logic;
        LED1         : out std_logic;
        LED2         : out std_logic;
        LED3         : out std_logic;
        LED4         : out std_logic;
        LED5         : out std_logic;
        LED6         : out std_logic;
        LED7         : out std_logic);
end entity LedTest;

library i2c, i2s, serial;

architecture structure of LedTest is
    signal conf_ratio   : std_logic_vector(7 downto 0);
    signal conf_res     : std_logic_vector(5 downto 0);
    signal conf_en      : std_logic;
    signal conf_swap    : std_logic;
    signal sample_dat_i : std_logic_vector(24 - 1 downto 0);
    signal sample_dat_o : std_logic_vector(24 - 1 downto 0);
    signal mem_rdwr     : std_logic;
    signal sample_addr  : std_logic_vector(10 - 2 downto 0);
    signal evt_lsbf     : std_logic;
    signal evt_hsbf     : std_logic;
    signal wb_rst_i     : std_logic;
    signal arst_i       : std_logic;
    signal wb_dat_i     : std_logic_vector(7 downto 0);
    signal Reset        : Std_Logic;
    signal IntRx_N      : Std_Logic;
    signal IntTx_N      : Std_Logic;
    signal Addr         : Std_Logic_Vector(1 downto 0);
    signal DataIn       : Std_Logic_Vector(7 downto 0);
    signal DataOut      : Std_Logic_Vector(7 downto 0);
begin

    audio_i2s_rx : entity i2s.i2s_codec
        generic map(
            DATA_WIDTH  => 24,
            ADDR_WIDTH  => 10,
            IS_MASTER   => 0,
            IS_RECEIVER => 1)
        port map(
            wb_clk_i     => Clk20M,
            conf_res     => conf_res,
            conf_ratio   => conf_ratio,
            conf_swap    => conf_swap,
            conf_en      => conf_en,
            i2s_sd_i     => i2s_sd_i,
            i2s_sck_i    => i2s_sck_i,
            i2s_ws_i     => i2s_ws_i,
            sample_dat_i => sample_dat_i,
            sample_dat_o => sample_dat_o,
            mem_rdwr     => mem_rdwr,
            sample_addr  => sample_addr,
            evt_hsbf     => evt_hsbf,
            evt_lsbf     => evt_lsbf,
            i2s_sd_o     => open,
            i2s_sck_o    => open,
            i2s_ws_o     => open);

    audio_i2s_tx : entity i2s.i2s_codec
        generic map(
            DATA_WIDTH  => 24,
            ADDR_WIDTH  => 10,
            IS_MASTER   => 0,
            IS_RECEIVER => 0)
        port map(
            wb_clk_i     => Clk20M,
            conf_res     => conf_res,
            conf_ratio   => conf_ratio,
            conf_swap    => conf_swap,
            conf_en      => conf_en,
            i2s_sd_i     => '0',
            i2s_sck_i    => '0',
            i2s_ws_i     => '0',
            sample_dat_i => sample_dat_i,
            sample_dat_o => sample_dat_o,
            mem_rdwr     => mem_rdwr,
            sample_addr  => sample_addr,
            evt_hsbf     => evt_hsbf,
            evt_lsbf     => evt_lsbf,
            i2s_sd_o     => i2s_sd_o,
            i2s_sck_o    => i2s_sck_o,
            i2s_ws_o     => i2s_ws_o);

    audio_i2c : entity i2c.i2c_master_top
        generic map(
            ARST_LVL => '0')
        port map(
            wb_clk_i     => Clk20M,
            wb_rst_i     => wb_rst_i,
            arst_i       => arst_i,
            wb_adr_i     => (others => '0'),
            wb_dat_i     => wb_dat_i,
            wb_dat_o     => open,
            wb_we_i      => wb_we_i,
            wb_stb_i     => wb_stb_i,
            wb_cyc_i     => wb_cyc_i,
            wb_ack_o     => wb_ack_o,
            wb_inta_o    => wb_inta_o,
            scl_pad_i    => scl_pad_i,
            scl_pad_o    => scl_pad_o,
            scl_padoen_o => scl_padoen_o,
            sda_pad_i    => sda_pad_i,
            sda_pad_o    => sda_pad_o,
            sda_padoen_o => sda_padoen_o);

    serial_uart : entity serial.miniUART
        port map(
            SysClk  => Clk20M,
            Reset   => Reset,
            CS_N    => CS_N,
            RD_N    => RD_N,
            WR_N    => WR_N,
            RxD     => RxD,
            TxD     => TxD,
            IntRx_N => IntRx_N,
            IntTx_N => IntTx_N,
            Addr    => Addr,
            DataIn  => DataIn,
            DataOut => DataOut);

end architecture structure;             -- of LedTest
