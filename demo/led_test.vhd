library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity LedTest is
    port(
        LED0 : out std_logic;
        LED1 : out std_logic;
        LED2 : out std_logic;
        LED3 : out std_logic;
        LED4 : out std_logic;
        LED5 : out std_logic;
        LED6 : out std_logic;
        LED7 : out std_logic);
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

    serial_uart : entity serial.uart
        port map(
            i_clk           => i_clk,
            i_srst          => i_srst,
            i_baud_div      => i_baud_div,
            o_uart_tx       => o_uart_tx,
            i_uart_rx       => i_uart_rx,
            i_tx_send       => i_tx_send,
            i_tx_send_we    => i_tx_send_we,
            o_tx_send_busy  => o_tx_send_busy,
            o_rx_read       => o_rx_read,
            o_rx_read_valid => o_rx_read_valid,
            i_rx_read_rd    => i_rx_read_rd);

end architecture structure;             -- of LedTest
