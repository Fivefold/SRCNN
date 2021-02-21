library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int32_add is
    port(
        A_i : in std_logic_vector(31 downto 0);
        B_i : in std_logic_vector(31 downto 0);
        C_o : out std_logic_vector(31 downto 0)
    );
end entity;

architecture normal of int32_add is
begin
    C_o <= std_logic_vector(signed(A_i) + signed(B_i));
end architecture;