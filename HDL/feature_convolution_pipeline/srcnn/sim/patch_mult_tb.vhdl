library ieee;
use ieee.std_logic_1164.all;

entity patch_mult_tb is
end entity;

architecture testbench of patch_mult_tb is
    component patch_mult is
        generic(
            KERNELSIZE : natural := 9
        );
        port(
            clk : in std_logic;
            rst : in std_logic;
        
            --start : in std_logic;
            valid_i : in std_logic;
            valid_o : out std_logic;
            stall_i : in std_logic;
            en_o : out std_logic;

            patch_val_i  : in std_logic_vector(31 downto 0);
            kernel_val_i : in std_logic_vector(31 downto 0);
            patch_val_o  : out std_logic_vector(31 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal clk, rst, valid_i, valid_o, stall_i, en_o : std_logic;
    signal patch_val, kernel_val, result : std_logic_vector(31 downto 0);
begin

    dut : patch_mult
    port map(
        clk => clk,
        rst => rst,
        valid_i => valid_i,
        valid_o => valid_o,
        stall_i => stall_i,
        en_o => en_o,
        patch_val_i => patch_val,
        kernel_val_i => kernel_val,
        patch_val_o => result
    );

    stimulus: process
    begin
        rst <= '1';
        valid_i <= '0';
        stall_i <= '0';
        patch_val <= (others =>'0');
        kernel_val <= (others => '0');
        wait for 1 ns;
        wait for CLK_PERIOD;

        rst <= '0';
        wait for CLK_PERIOD*2;

        patch_val <= "00000100000000000000000000000000"; --1
        kernel_val <= "00001000000000000000000000000000"; --2
        wait for CLK_PERIOD;

        valid_i <= '1';
        wait for CLK_PERIOD;

        kernel_val <= "00000100000000000000000000000000"; --1
        wait for CLK_PERIOD;

        patch_val <= "00001000000000000000000000000000"; --2
        kernel_val <= "00001000000000000000000000000000"; --2
        stall_i <= '1';
        wait for CLK_PERIOD;

        patch_val <= "00000010000000000000000000000000"; --0.5
        kernel_val <= "00000010000000000000000000000000"; --0.5
        stall_i <= '0';
        wait for CLK_PERIOD;

        patch_val <= "10000100000000000000000000000000"; --
        kernel_val <= "10000100000000000000000000000000"; --
        valid_i <= '0';
        wait for CLK_PERIOD;

        patch_val <= "00000100000000000000000000000000"; --1
        kernel_val <= "00000100000000000000000000000000"; --1
        valid_i <= '1';
        wait for CLK_PERIOD;

        patch_val <= "00000010000000000000000000000000"; --0.5
        kernel_val <= "00000010000000000000000000000000"; --0.5
        stall_i <= '1';
        wait for CLK_PERIOD*6;

        patch_val <= "00000100000000000000000000000000"; --1
        kernel_val <= "00000100000000000000000000000000"; --1
        stall_i <= '0';

        wait for CLK_PERIOD*10;

        valid_i <= '0';

        wait;

    end process;

    clk_gen: process
    begin
        clk <= '1';
        wait for CLK_PERIOD/2;
        clk <= '0';
        wait for CLK_PERIOD/2;
    end process;

end architecture;