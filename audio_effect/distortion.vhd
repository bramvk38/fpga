------------------------------------------------------------------------------------------------
--  distortion.vhd
------------------------------------------------------------------------------------------------
-- Efecto de distorsion.
-- Dado un valor parametrizado se recorta la senal para que no supere ese umbral.
-- El recorte se hace en la parte positiva y negativa de la senal.
------------------------------------------------------------------------------------------------
-- Jose Angel Gumiel
--  25/11/2016
-- BraKer: change to flexible DW: 11/09/2018
------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity distortion is
    generic(
        DW : natural := 16);
    port(
        -- Data
        sample_in  : in  std_logic_vector(DW - 1 downto 0);
        sample_out : out std_logic_vector(DW - 1 downto 0);
        -- Parameters
        gain       : in  std_logic_vector(DW - 1 downto 0);
        dist_pos   : in  std_logic_vector(DW - 1 downto 0));
end entity distortion;

library audio_effect;

architecture a of distortion is
    signal dist_neg    : std_logic_vector(DW - 1 downto 0);
    signal signal_dist : std_logic_vector(DW - 1 downto 0);
begin

    dist_neg <= -dist_pos;
    boost : process(dist_pos, dist_neg)
    begin
        if (sample_in(DW - 1) = '1') then --resultado negativo
            if (signed(sample_in(DW - 1 downto 0)) < signed(dist_neg(DW - 1 downto 0))) then --CUIDADO!!!
                signal_dist <= dist_neg;
            else
                signal_dist <= sample_in;
            end if;
        else                            --resultado positivo
            if (signed(sample_in(DW - 1 downto 0)) > signed(dist_pos(DW - 1 downto 0))) then
                signal_dist <= dist_pos;
            else
                signal_dist <= sample_in;
            end if;
        end if;

    end process;

    --La distorsion recorta la amplitud de onda, quiero amplificarla.
    boost_eff : entity audio_effect.booster
        generic map(
            DW => DW)
        port map(
            sample_in  => signal_dist,
            sample_out => sample_out,
            multiplier => gain);

end architecture a;
