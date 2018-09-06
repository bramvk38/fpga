library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

package pkgarray is

    type data_8b_array is array (natural range <>) of std_logic_vector(7 downto 0);

end package pkgarray;
