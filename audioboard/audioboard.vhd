library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity AudioBoard is
    port(
        -- Board default pins
        ClkSys      : in    std_logic;  -- pin 23 - System Clk (50M) 
        ClkUser     : in    std_logic;  -- pin 24 - User Clk (NA)
        LED0        : out   std_logic;  -- pin 73 - LED0 
        LED1        : out   std_logic;  -- pin 74 - LED1 
        LED2        : out   std_logic;  -- pin 75 - LED2 
        LED3        : out   std_logic;  -- pin 76 - LED3 
        LED4        : out   std_logic;  -- pin 77 - LED4 
        LED5        : out   std_logic;  -- pin 83 - LED5 
        LED6        : out   std_logic;  -- pin 84 - LED6 
        LED7        : out   std_logic;  -- pin 85 - LED7 
        KEY0        : in    std_logic;  -- pin 86 - KEY0 
        KEY1        : in    std_logic;  -- pin 87 - KEY1
        -- Project pins
        AudioScl    : inout std_logic;  -- pin 46 - UDA1380 i2c interface
        AudioSda    : inout std_logic;  -- pin 42
        AudioMCLK   : out   std_logic;  -- pin 43 - UDA1380 system clock
        AudioTxClk  : out   std_logic;  -- pin 39 - connect to Rx on UDA138
        AudioTxWs   : out   std_logic;  -- pin 33
        AudioTxData : out   std_logic;  -- pin 31
        AudioRxClk  : in    std_logic;  -- pin 38 - connect to Tx on UDA1380
        AudioRxWs   : in    std_logic;  -- pin 34
        AudioRxData : in    std_logic;  -- pin 32
        UartTx      : out   std_logic;  -- pin 51 - UART control/register interface
        UartRx      : in    std_logic); -- pin 52
end entity AudioBoard;

library serial, uart2reg, i2c_master, i2s;

architecture mixed of AudioBoard is
    -- UART
    signal UartTx_data      : std_logic_vector(7 downto 0);
    signal UartTx_write     : std_logic;
    signal UartTx_busy      : std_logic;
    signal UartRx_data      : std_logic_vector(7 downto 0);
    signal UartRx_valid     : std_logic;
    signal UartRx_read      : std_logic;
    -- Registers
    signal Reg_Written      : std_logic;
    signal LedCtrl          : std_logic_vector(7 downto 0);
    signal KeyStat          : std_logic_vector(7 downto 0);
    signal UDA1380_Ctrl     : std_logic_vector(7 downto 0);
    signal UDA1380_Addr     : std_logic_vector(7 downto 0);
    signal UDA1380_WrMb     : std_logic_vector(7 downto 0);
    signal UDA1380_WrLb     : std_logic_vector(7 downto 0);
    signal UDA1380_RrMb     : std_logic_vector(7 downto 0);
    signal UDA1380_RrLb     : std_logic_vector(7 downto 0);
    -- I2C UDA1380
    signal TIC              : std_logic;
    signal counter          : std_logic_vector(7 downto 0);
    signal SCL_IN           : std_logic;
    signal SCL_OUT          : std_logic;
    signal SDA_IN           : std_logic;
    signal SDA_OUT          : std_logic;
    --  I2S UDA1380
    signal AudioSampleTx    : std_logic_vector(19 downto 0);
    signal AudioSampleRx    : std_logic_vector(19 downto 0);
    signal AudioSampleValid : std_logic;
    -- altpll: clock generation
    signal ClkAudio         : std_logic; -- UDA1380 sysclk => 256 x 48 (fs) = 12.288 MHz
    signal RstAudio_n       : std_logic;
    signal RstAudio         : std_logic;
    component uda1380pll
        port(
            inclk0 : in  std_logic := '0';
            c0     : out std_logic;
            locked : out std_logic);
    end component;
    -- Audio Effect : pitch shifter
    component EBABWrapper
        port(
            -- Outputs
            bus_byte_enable         : out std_logic_vector(3 downto 0);
            bus_read                : out std_logic;
            bus_write               : out std_logic;
            bus_write_data          : out std_logic_vector(31 downto 0);
            bus_addr                : out std_logic_vector(31 downto 0);
            -- Inputs
            clk                     : in  std_logic;
            rst                     : in  std_logic;
            out_sel                 : in  std_logic;
            delta_mode_left         : in  std_logic;
            delta_mode_right        : in  std_logic;
            bus_ack                 : in  std_logic;
            bus_read_data           : in  std_logic_vector(31 downto 0);
            delta_left              : in  std_logic_vector(31 downto 0);
            delta_right             : in  std_logic_vector(31 downto 0);
            triangle_wave_max_left  : in  std_logic_vector(9 downto 0);
            triangle_wave_max_right : in  std_logic_vector(9 downto 0));
    end component;
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

    -- PLL 12.288M sysclk for UDA1380
    audio_mclk : uda1380pll
        port map(
            inclk0 => ClkSys,
            c0     => ClkAudio,
            locked => RstAudio_n);
    RstAudio  <= not RstAudio_n;
    AudioMCLK <= ClkAudio;

    -- I2S UDA 1380 audio codec
    i2s_UDA1380 : entity i2s.i2s_interface
        generic map(
            DATA_WIDTH  => 20,
            BITPERFRAME => 64)
        port map(
            clk        => ClkAudio,
            reset      => RstAudio,
            bclk       => AudioRxClk,
            lrclk      => AudioRxWs,
            sample_out => AudioSampleRx,
            sample_in  => AudioSampleTx,
            dac_data   => AudioTxData,
            adc_data   => AudioRxData,
            valid      => AudioSampleValid,
            ready      => open);
    AudioTxClk <= AudioRxClk;
    AudioTxWs  <= AudioRxWs;

    AudioSampleTx <= AudioSampleRx;     -- Loop back

    -- I2C UDA 1380 audio codec module
    i2c_UDA1380 : entity i2c_master.I2cMaster_UDA1380
        generic map(
            DEVICE => X"18")
        port map(
            Clk     => ClkSys,
            TIC     => TIC,
            Read    => UDA1380_Ctrl(0) and Reg_Written,
            Write   => UDA1380_Ctrl(1) and Reg_Written,
            Addr    => UDA1380_Addr,
            WrMSB   => UDA1380_WrMb,
            WrLSB   => UDA1380_WrLb,
            RdMSB   => UDA1380_RrMb,
            RdLSB   => UDA1380_RrLb,
            SCL_IN  => SCL_IN,
            SCL_OUT => SCL_OUT,
            SDA_IN  => SDA_IN,
            SDA_OUT => SDA_OUT);

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

    --  open drain PAD pull up 1.5K needed => 1k pull up on UDA1380
    AudioScl <= 'Z' when SCL_OUT = '1' else '0';
    SCL_IN   <= to_UX01(AudioScl);
    AudioSda <= 'Z' when SDA_OUT = '1' else '0';
    SDA_IN   <= to_UX01(AudioSda);

    -- Registers
    registers : entity uart2reg.uart2reg
        generic map(
            N => 8)
        port map(
            Clk          => ClkSys,
            UartTx_data  => UartTx_data,
            UartTx_write => UartTx_write,
            UartTx_busy  => UartTx_busy,
            UartRx_data  => UartRx_data,
            UartRx_valid => UartRx_valid,
            UartRx_read  => UartRx_read,
            Reg_Written  => Reg_Written,
            Reg_Read(0)  => LedCtrl,    -- Read Back
            Reg_Read(1)  => KeyStat,
            Reg_Read(2)  => UDA1380_Ctrl, -- Read Back
            Reg_Read(3)  => UDA1380_Addr, -- Read Back
            Reg_Read(4)  => UDA1380_WrMb, -- Read Back
            Reg_Read(5)  => UDA1380_WrLb, -- Read Back
            Reg_Read(6)  => UDA1380_RrMb,
            Reg_Read(7)  => UDA1380_RrLb,
            Reg_Write(0) => LedCtrl,
            Reg_Write(1) => open,
            Reg_Write(2) => UDA1380_Ctrl,
            Reg_Write(3) => UDA1380_Addr,
            Reg_Write(4) => UDA1380_WrMb,
            Reg_Write(5) => UDA1380_WrLb,
            Reg_Write(6) => open,
            Reg_Write(7) => open);

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
