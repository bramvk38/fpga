-- main simple register uart 
-- fpga slave; fpga never sends data on it's own, only responds with 1 word (8b) to read-request
-- no burst-writes; only 1 word (8b) every write-request
--
-- braker 06-09-18

library ieee, uart2reg;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use uart2reg.pkgarray.all;

entity uart2reg is
    generic(
        N : natural := 4);
    port(
        Clk          : in  std_logic;
        -- UART Interface
        UartTx_data  : out std_logic_vector(7 downto 0);
        UartTx_write : out std_logic;
        UartTx_busy  : in  std_logic;
        UartRx_data  : in  std_logic_vector(7 downto 0);
        UartRx_valid : in  std_logic;
        UartRx_read  : out std_logic;
        -- Registers
        Reg_Written  : out std_logic;
        Reg_Read     : in  data_8b_array(N - 1 downto 0);
        Reg_Write    : out data_8b_array(N - 1 downto 0));
end entity uart2reg;

architecture rtl of uart2reg is
    type T_States is (S_IDLE, S_WRITE_REG, S_READ_REG);
    signal State : T_States := S_IDLE;

    constant RdCmd : std_logic_vector(0 downto 0) := "0";
    constant WrCmd : std_logic_vector(0 downto 0) := "1";
    constant CMD   : std_logic_vector(7 downto 7) := (others => '0');
    constant ADDR  : std_logic_vector(6 downto 0) := (others => '0');

    signal Address     : std_logic_vector(6 downto 0) := (others => '0');
    signal TxData      : std_logic_vector(7 downto 0) := (others => '0');
    signal RxData      : std_logic_vector(7 downto 0) := (others => '0');
    signal RxDataValid : std_logic                    := '0';
    signal valid_cpy   : std_logic;
begin

    -- TxData select (return FF when address is out of range)
    TxData <= Reg_Read(to_integer(unsigned(Address))) when to_integer(unsigned(Address)) < N else X"FF";

    p_WriteReg : process(Clk)
    begin
        if rising_edge(Clk) then
            Reg_Written <= '0';
            if RxDataValid = '1' and to_integer(unsigned(Address)) < N then -- RxData valid & address exists
                Reg_Write(to_integer(unsigned(Address))) <= RxData;
                Reg_Written                              <= '1';
            end if;
        end if;
    end process;

    p_State : process(Clk)
    begin
        if rising_edge(Clk) then
            valid_cpy    <= UartRx_valid;
            RxDataValid  <= '0';
            UartTx_write <= '0';
            UartRx_read  <= '0';
            case State is
                when S_IDLE =>
                    if UartRx_valid = '1' and valid_cpy = '0' then -- rising edge valid
                        Address     <= UartRx_data(ADDR'range);
                        UartRx_read <= '1';
                        if UartRx_data(CMD'range) = WrCmd then
                            State <= S_WRITE_REG;
                        elsif UartRx_data(CMD'range) = RdCmd then
                            State <= S_READ_REG;
                        end if;
                    end if;
                when S_WRITE_REG =>
                    if UartRx_valid = '1' and valid_cpy = '0' then -- rising edge valid
                        RxData      <= UartRx_data;
                        RxDataValid <= '1';
                        UartRx_read <= '1';
                        State       <= S_IDLE;
                    end if;
                when S_READ_REG =>
                    UartTx_data  <= TxData;
                    UartTx_write <= '1';
                    if UartTx_busy = '0' then
                        State <= S_IDLE;
                    end if;
            end case;
        end if;
    end process;

end architecture rtl;                   -- of uart2reg