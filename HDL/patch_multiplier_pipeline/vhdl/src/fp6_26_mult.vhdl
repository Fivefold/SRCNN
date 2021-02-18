library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp6_26_mult is
    port(
        clk : in std_logic;
        en : in std_logic;
        A_i : in std_logic_vector(31 downto 0);
        B_i : in std_logic_vector(31 downto 0);
        C_o : out std_logic_vector(31 downto 0)
    );
end entity;

architecture logicore of fp6_26_mult is

    COMPONENT mult_gen_0
        PORT (
            CLK : IN STD_LOGIC;
            A : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            B : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            CE : IN STD_LOGIC;
            P : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
        );
    END COMPONENT;

    signal result : std_logic_vector(63 downto 0);
begin

    logicore_mult1 : mult_gen_0
        PORT MAP (
            CLK => clk,
            A => A_i,
            B => B_i,
            CE => en,
            P => result
        );

    C_o <= result(57 downto 26);

end architecture;