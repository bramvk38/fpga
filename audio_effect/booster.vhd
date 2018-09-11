------------------------------------------------------------------------------------------------
--  booster.vhd
------------------------------------------------------------------------------------------------
-- Etapa de amplificacion limpia.
-- Dado un valor parametrizado multiplica la senal de entrada y retorna dicha senal amplificada.
-- Se descartan los 9 bits mas significativos despues del signo para controlar la ganancia.
------------------------------------------------------------------------------------------------
-- Jose Angel Gumiel
--  25/11/2016
-- BraKer: change to flexible DW: 11/09/2018
------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity booster is
    generic(
        DW : natural := 16);
    port(
        -- Data
        sample_in  : in  std_logic_vector(DW - 1 downto 0);
        sample_out : out std_logic_vector(DW - 1 downto 0);
        -- Parameters
        multiplier : in  std_logic_vector(DW - 1 downto 0));
end entity booster;

architecture a of booster is
    constant LOW               : natural := DW / 2;
    constant HIGH              : natural := LOW + DW - 2;
    signal signal_unnormalized : std_logic_vector(DW * 2 - 1 downto 0);
begin

    signal_unnormalized <= signed(sample_in) * signed(multiplier);
    boost : process(signal_unnormalized)
    begin
        if (signal_unnormalized(31) = '1') then --resultado negativo
            sample_out <= '1' & signal_unnormalized(HIGH downto LOW);
        else                            --resultado positivo
            sample_out <= '0' & signal_unnormalized(HIGH downto LOW);
        end if;
    end process;

end architecture a;
