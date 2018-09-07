library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity AudioBoard is
    port(
        -- Board default pins
        ClkSys   : in    std_logic;     --System Clk 50M, pin 23
        ClkUser  : in    std_logic;     --User Clk, pin 24 (NA)
        LED0     : out   std_logic;     --LED0, IO 73
        LED1     : out   std_logic;     --LED1, IO 74
        LED2     : out   std_logic;     --LED2, IO 75
        LED3     : out   std_logic;     --LED3, IO 76
        LED4     : out   std_logic;     --LED4, IO 77
        LED5     : out   std_logic;     --LED5, IO 83
        LED6     : out   std_logic;     --LED6, IO 84
        LED7     : out   std_logic;     --LED7, IO 85
        KEY0     : in    std_logic;     --KEY0, pin 86
        KEY1     : in    std_logic;     --KEY0, pin 87
        -- Project pins
        AudioScl : inout std_logic;
        AudioSda : inout std_logic;
        UartTx   : out   std_logic;     -- pin 51
        UartRx   : in    std_logic);    -- pin 52
end entity AudioBoard;

library serial, uart2reg, i2c, i2s;

architecture mixed of AudioBoard is
    -- UART
    signal UartTx_data  : std_logic_vector(7 downto 0);
    signal UartTx_write : std_logic;
    signal UartTx_busy  : std_logic;
    signal UartRx_data  : std_logic_vector(7 downto 0);
    signal UartRx_valid : std_logic;
    signal UartRx_read  : std_logic;
    -- Registers
    signal LedCtrl      : std_logic_vector(7 downto 0);
    signal KeyStat      : std_logic_vector(7 downto 0);
    -- I2C UDA1380
    signal TIC          : std_logic;
    signal counter      : std_logic_vector(7 downto 0);
    signal SCL_IN       : std_logic;
    signal SCL_OUT      : std_logic;
    signal SDA_IN       : std_logic;
    signal SDA_OUT      : std_logic;
begin

    -- Assign LED outputs
    LED0 <= not LedCtrl(0) and KEY0;
    LED1 <= not LedCtrl(1) and KEY1;
    LED2 <= not LedCtrl(2);
    LED3 <= not LedCtrl(3);
    LED4 <= not LedCtrl(4);
    LED5 <= not LedCtrl(5);
    LED6 <= not LedCtrl(6);
    LED7 <= not LedCtrl(7);

    -- Assign KEY status register
    KeyStat(0)          <= not KEY0;
    KeyStat(1)          <= not KEY1;
    KeyStat(7 downto 2) <= (others => '0');

    -- I2S Rx UDA 1380 audio codec module
    --i2s_rx_UDA1380 : entity i2s.rx_i2s_tops

    -- I2C UDA 1380 audio codec module
    i2c_UDA1380 : entity i2c.I2CMASTER
        generic map(
            DEVICE => x"38")
        port map(
            MCLK       => ClkSys,
            nRST       => '1',
            SRST       => '0',
            TIC        => TIC,
            DIN        => DIN,
            DOUT       => DOUT,
            RD         => RD,
            WE         => WE,
            NACK       => NACK,
            QUEUED     => QUEUED,
            DATA_VALID => DATA_VALID,
            STOP       => STOP,
            STATUS     => STATUS,
            SCL_IN     => SCL_IN,
            SCL_OUT    => SCL_OUT,
            SDA_IN     => SDA_IN,
            SDA_OUT    => SDA_OUT);

    gen_TIC : process(ClkSys)
    begin
        if rising_edge(ClkSys) then
            if counter = 160 then       -- 50M / 160 = ~300 khz for ~100 kbit
                TIC     <= '1';
                counter <= (others => '0');
            else
                TIC     <= '0';
                counter <= counter + 1;
            end if;
        end if;
    end process;

    --  open drain PAD pull up 1.5K needed
    AudioScl <= 'Z' when SCL_OUT = '1' else '0';
    SCL_IN   <= to_UX01(AudioScl);
    AudioSda <= 'Z' when SDA_OUT = '1' else '0';
    SDA_IN   <= to_UX01(AudioSda);

    -- Registers
    registers : entity uart2reg.uart2reg
        generic map(
            N => 2)
        port map(
            Clk          => ClkSys,
            UartTx_data  => UartTx_data,
            UartTx_write => UartTx_write,
            UartTx_busy  => UartTx_busy,
            UartRx_data  => UartRx_data,
            UartRx_valid => UartRx_valid,
            UartRx_read  => UartRx_read,
            Reg_Read(0)  => LedCtrl,
            Reg_Read(1)  => KeyStat,
            Reg_Write(0) => LedCtrl,
            Reg_Write(1) => open);

    -- UART interface
    serial_simple : entity serial.uart
        port map(
            i_clk           => ClkSys,
            i_srst          => '0',
            i_baud_div      => X"01B2", -- 50M / 434 = 115207 bps
            o_uart_tx       => UartTx,
            i_uart_rx       => UartRx,
            i_tx_send       => UartTx_data,
            i_tx_send_we    => UartTx_write,
            o_tx_send_busy  => UartTx_busy,
            o_rx_read       => UartRx_data,
            o_rx_read_valid => UartRx_valid,
            i_rx_read_rd    => UartRx_read);

end architecture mixed;                 -- of AudioBoard
