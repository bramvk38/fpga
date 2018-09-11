------------------------------------------------------------------------------------------------
--  tremolo.vhd
------------------------------------------------------------------------------------------------
-- Etapa de amplificacion limpia.
-- Dado un valor parametrizado multiplica la senal de entrada y retorna dicha senal amplificada.
-- Se descartan los 9 bits mas significativos despues del signo para controlar la ganancia.
------------------------------------------------------------------------------------------------
-- Jose Angel Gumiel
--  11/02/2017
-- BraKer: change to flexible DW: 11/09/2018
------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity tremolo is
    generic(
        DW : natural := 16);
    port(
        clk        : in  std_logic;
        -- Data
        sample_in  : in  std_logic_vector(DW - 1 downto 0);
        sample_out : out std_logic_vector(DW - 1 downto 0);
        LD_Sample  : in  std_logic;
        cl         : in  std_logic;
        -- Parameters
        rate       : in  std_logic_vector(DW - 1 downto 0); --Velocidad del tremolo
        atack      : in  std_logic_vector(DW - 1 downto 0); --Como va a ser la diferencia entre la amplitud minima y la maxima.
        wave       : in  std_logic_vector(1 downto 0)); --Forma de la onda. Seno, cuadrada, triangular?
end entity tremolo;

library audio_effect;

architecture a of tremolo is

    signal amplitude   : std_logic_vector(DW - 1 downto 0);
    signal cls_counter : std_logic_vector(DW downto 0);
    signal doble       : std_logic_vector(DW downto 0);
    constant cero      : std_logic_vector(DW downto 0)     := (others => '0');
    --Valores que toma la amplitud
    constant low_gain  : std_logic_vector(DW - 1 downto 0) := std_logic_vector(RESIZE(unsigned("0000000010000001"), DW));
    constant high_gain : std_logic_vector(DW - 1 downto 0) := std_logic_vector(RESIZE(unsigned("0000001111111111"), DW));
    --Valores que toma la frecuencia
    signal ratio       : std_logic_vector(DW - 1 downto 0); --El valor que almaceno de lo que llega del ADC (Pot)
    signal ataque      : std_logic_vector(DW - 1 downto 0); --El valor que almaceno de lo que llega del ADC (Pot)
    constant max_freq  : std_logic_vector(DW - 1 downto 0) := std_logic_vector(RESIZE(unsigned("0000100101100000"), DW)); --10Hz (Subida y bajada en 100ms)
    constant min_freq  : std_logic_vector(DW - 1 downto 0) := std_logic_vector(RESIZE(unsigned("0100011001010000"), DW)); --1.5Hz
    --Cuando empieza el ciclo?
    signal LD_Div      : std_logic;

begin
    --Quiero definir un ratio minimo y maximo. El ratio SOLO quiero que se actualice cuando haya terminado de contar.
    ratio <= max_freq when (rate < max_freq and cls_counter = cero)
        else                            --10Hz
        min_freq when (rate > min_freq and cls_counter = cero)
        else                            --1.5Hz
        rate when (cls_counter = cero)
    ;

    --Lo mismo para el ataque. Solo quiero que se actualice en cada ciclo.
    ataque <= atack when (cls_counter = cero);

    tremolo : process(clk)
    begin
        doble <= ratio(DW downto 1) & '0';
        if (cl = '1') then
            cls_counter <= cero;
        elsif (clk'event and clk = '1') then
            if (LD_Sample = '1') then
                if (cls_counter = doble) then
                    cls_counter <= cero;
                    LD_Div      <= '1'; --Para llamar a la division
                else
                    cls_counter <= cls_counter + '1';
                    LD_Div      <= '0';
                end if;
            end if;
        end if;
    end process;

    --s0    Instanciar un componente que me diga que amplitud usar.
    s0 : entity audio_effect.wave_setup
        generic map(
            DW => DW)
        port map(rate     => ratio,
                 wave     => wave,
                 atack    => ataque,
                 gain     => amplitude,
                 counter  => cls_counter,
                 LD_Div   => LD_Div,
                 clk_Samp => LD_Sample,
                 clk      => clk,
                 cl       => cl);

    s1 : entity audio_effect.booster
        generic map(
            DW => DW)
        port map(sample_in  => sample_in,
                 sample_out => sample_out,
                 multiplier => amplitude);

end architecture a;
