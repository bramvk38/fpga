library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- UDA1380 I2C protocol
-- Write request:
-- S | DEV ADDR | RW=0 | sAck | REG ADDR | sAck | MSB | sAck | LSB | sAck | P
-- Read request:
-- S | DEV ADDR | RW=0 | sAck | REG ADDR | sAck | Sr | DEV ADDR | RW=1 | sAck | MSB | mAck | LSB | mNAck | P

entity I2cMaster_UDA1380 is
    generic(
        DEVICE : std_logic_vector(7 downto 0) := x"38");
    port(
        -- Clk / TIC
        Clk     : in  std_logic;
        TIC     : in  std_logic;        -- i2c rate (bit rate x3)
        -- R/W request
        Read    : in  std_logic;
        Write   : in  std_logic;
        Addr    : in  std_logic_vector(7 downto 0); -- register address
        WrMSB   : in  std_logic_vector(7 downto 0); -- wr-data 15-8
        WrLSB   : in  std_logic_vector(7 downto 0); -- wr-data 7-0
        RdMSB   : out std_logic_vector(7 downto 0); -- rd-data 15-8
        RdLSB   : out std_logic_vector(7 downto 0); -- rd-data 7-0
        -- I2C signals
        SCL_IN  : in  std_logic;
        SCL_OUT : out std_logic;
        SDA_IN  : in  std_logic;
        SDA_OUT : out std_logic);
end I2cMaster_UDA1380;

architecture rtl of I2cMaster_UDA1380 is

    type tstate is (S_IDLE, S_START, S_WRITE_ADDR, S_WRITE_MSB, S_WRITE_LSB,
                    S_READ_SR, S_READ_DEV, S_READ_MSB, S_READ_LSB, S_END, S_PRESTOP, S_STOP,
                    S_SENDBYTE, S_WESCLUP, S_WESCLDOWN, S_CHECKACK, S_CHECKACKUP, S_CHECKACKDOWN,
                    S_RECVBYTE, S_RDSCLUP, S_RDSCLDOWN, S_SENDACK, S_SENDACKUP, S_SENDACKDOWN);
    signal state               : tstate                       := S_IDLE;
    signal next_state          : tstate                       := S_IDLE;
    signal counter             : std_logic_vector(3 downto 0) := (others => '0');
    signal next_counter        : std_logic_vector(3 downto 0);
    signal shift               : std_logic_vector(7 downto 0) := (others => '0');
    signal sda_in_q, sda_in_qq : std_logic                    := '1';
	 signal writing             : std_logic                    := '0';

begin

    next_counter <= std_logic_vector(to_unsigned(to_integer(unsigned(counter)) + 1, 4));

    p_State : process(Clk)
    begin
        if rising_edge(Clk) then

            sda_in_q  <= SDA_IN;
            sda_in_qq <= sda_in_q;

            -- IDLE
            if (state = S_IDLE) then
                SCL_OUT <= '1';
                SDA_OUT <= '1';
                counter <= (others => '0');
                    if (Write = '1' or Read = '1') then
                        state <= S_START;
								if (Write = '1') then
								    writing <= '1';
							   else
								    writing <= '0';
									 end if;
                    end if;

            -- DEVICE ID
            elsif (state = S_START) then
                SCL_OUT <= '1';
                SDA_OUT <= '0';         -- start bit
                if (TIC = '1') then
                    SCL_OUT           <= '0';
                    counter           <= "0000";
                    shift(7 downto 1) <= DEVICE(6 downto 0);
                    shift(0)          <= '0';
                    next_state        <= S_WRITE_ADDR;
                    state             <= S_SENDBYTE;
                end if;

            -- REGISTER ADDR
            elsif (state = S_WRITE_ADDR) then
                counter <= "0000";
                shift   <= Addr;
                if (writing = '1') then
                    next_state <= S_WRITE_MSB;
                else
                    next_state <= S_READ_SR;
                end if;
                state   <= S_SENDBYTE;

            -- WRITE
            elsif (state = S_WRITE_MSB) then
                counter    <= "0000";
                shift      <= WrMSB;
                next_state <= S_WRITE_LSB;
                state      <= S_SENDBYTE;
            elsif (state = S_WRITE_LSB) then
                counter    <= "0000";
                shift      <= WrLSB;
                next_state <= S_END;
                state      <= S_SENDBYTE;

            -- READ
            elsif (state = S_READ_SR) then
                SCL_OUT <= '1';
                SDA_OUT <= '1';
                if (TIC = '1') then
                    SDA_OUT <= '0';     -- Repeater start
                    state   <= S_READ_DEV;
                end if;
            elsif (state = S_READ_DEV) then
                counter           <= "0000";
                shift(7 downto 1) <= DEVICE(6 downto 0);
                shift(0)          <= '1'; -- Read
                next_state        <= S_READ_MSB;
                state             <= S_SENDBYTE;
            elsif (state = S_READ_MSB) then
                shift      <= (others => '0');
                counter    <= "0000";
                next_state <= S_READ_LSB;
                state      <= S_RECVBYTE;
            elsif (state = S_READ_LSB) then
                shift      <= (others => '0');
                counter    <= "0000";
                next_state <= S_END;
                state      <= S_RECVBYTE;

            -- SEND BYTE
            elsif (state = S_SENDBYTE) then
                if (TIC = '1') then
                    SCL_OUT           <= '0';
                    SDA_OUT           <= shift(7);
                    shift(7 downto 1) <= shift(6 downto 0);
                    counter           <= next_counter;
                    state             <= S_WESCLUP;
                end if;
            elsif (state = S_WESCLUP) then
                if (TIC = '1') then
                    SCL_OUT <= '1';
                    state   <= S_WESCLDOWN;
                end if;
            elsif (state = S_WESCLDOWN) then
                if (TIC = '1') then
                    SCL_OUT <= '0';
                    if (counter(3) = '1') then
                        state <= S_CHECKACK;
                    else
                        state <= S_SENDBYTE;
                    end if;
                end if;
            elsif (state = S_CHECKACK) then
                if (TIC = '1') then
                    SDA_OUT <= '1';
                    SCL_OUT <= '0';
                    state   <= S_CHECKACKUP;
                end if;
            elsif (state = S_CHECKACKUP) then
                if (TIC = '1') then
                    SCL_OUT <= '1';
                    state   <= S_CHECKACKDOWN;
                end if;
            elsif (state = S_CHECKACKDOWN) then
                if (TIC = '1') then
                    SCL_OUT <= '0';
                    state   <= next_state;
                end if;

            -- RECEIVE BYTE
            elsif (state = S_RECVBYTE) then
                if (TIC = '1') then
                    SDA_OUT <= '1';
                    SCL_OUT <= '0';
                    counter <= next_counter;
                    state   <= S_RDSCLUP;
                end if;
            elsif (state = S_RDSCLUP) then
                if (TIC = '1') then
                    SCL_OUT           <= '1';
                    shift(7 downto 1) <= shift(6 downto 0);
                    shift(0)          <= sda_in_qq;
                    state             <= S_RDSCLDOWN;
                end if;
            elsif (state = S_RDSCLDOWN) then
                if (TIC = '1') then
                    SCL_OUT <= '0';
                    if (counter(3) = '1') then
                        state <= S_SENDACK;
                    else
                        state <= S_RECVBYTE;
                    end if;
                end if;
            elsif (state = S_SENDACK) then
                if (TIC = '1') then
                    if (next_state = S_READ_LSB) then
                        SDA_OUT <= '0';
                        RdMSB   <= shift;
                    else
                        SDA_OUT <= '1'; -- last read
                        RdLSB   <= shift;
                    end if;
                    SCL_OUT <= '0';
                    state <= S_SENDACKUP;
                end if;
            elsif (state = S_SENDACKUP) then
                if (TIC = '1') then
                    -- SDA_OUT <= '0';
                    SCL_OUT <= '1';
                    state   <= S_SENDACKDOWN;
                end if;
            elsif (state = S_SENDACKDOWN) then
                if (TIC = '1') then
                    -- SDA_OUT <= '0';
                    SCL_OUT <= '0';
                    state   <= next_state;
                end if;

            -- STOP
            elsif (state = S_END) then
                SCL_OUT <= '0';
                if (TIC = '1') then
                    SDA_OUT <= '0';
                    state   <= S_PRESTOP;
                end if;
            elsif (state = S_PRESTOP) then
                if (TIC = '1') then
                    SCL_OUT <= '1';
                    SDA_OUT <= '0';
                    state   <= S_STOP;
                end if;
            elsif (state = S_STOP) then
                if (TIC = '1') then
                    SCL_OUT <= '1';
                    SDA_OUT <= '1';
                    state   <= S_IDLE;
                end if;
            end if;
        end if;
    end process;

end rtl;                                -- of I2cMaster_UDA1380
