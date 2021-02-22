library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.config_pkg.all;

entity patch_mult is
    port(
        clk : in std_logic;
        rst : in std_logic;

        kernelsize : in integer range 0 to KERNELSIZE_MAX;
    
        valid_i : in std_logic;
        valid_o : out std_logic;
        stall_i : in std_logic;
        en_o : out std_logic;

        patch_val_i  : in std_logic_vector(31 downto 0);
        kernel_val_i : in std_logic_vector(31 downto 0);
        patch_val_o  : out std_logic_vector(31 downto 0)
    );
end entity;

architecture archi of patch_mult is
    component fp6_26_mult is
        port(
            clk : in std_logic;
            en : in std_logic;
            A_i : in std_logic_vector(31 downto 0);
            B_i : in std_logic_vector(31 downto 0);
            C_o : out std_logic_vector(31 downto 0)
        );
    end component;

    component int32_add is
        port(
            A_i : in std_logic_vector(31 downto 0);
            B_i : in std_logic_vector(31 downto 0);
            C_o : out std_logic_vector(31 downto 0)
        );
    end component;

    signal product : std_logic_vector(31 downto 0);
    signal summation, summation_reg : std_logic_vector(31 downto 0);
    signal summand_B : std_logic_vector(31 downto 0);
    signal valid_reg : std_logic_vector(1 downto 0); -- multiplier has just 2 pipeline stages
    signal summation_cnt_x : integer range 0 to KERNELSIZE_MAX - 1;
    signal summation_cnt_y : integer range 0 to KERNELSIZE_MAX - 1;
    signal en : std_logic;
    signal valid_int : std_logic;
begin

    mult_i : fp6_26_mult
    port map(
        clk => clk,
        en => en,
        A_i => patch_val_i,
        B_i => kernel_val_i,
        C_o => product
    );

    add_i : int32_add
    port map(
        A_i => product,
        B_i => summand_B,
        C_o => summation
    );
    
    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then
                summation_reg <= (others => '0');
                summation_cnt_x <= 0;
                summation_cnt_y <= 0;
                valid_reg <= (others => '0');
                valid_int <= '0';
            else

                if en = '1' then
                    if valid_reg(1) = '1' then

                        valid_int <= '0';
                        if summation_cnt_x < kernelsize - 1 then
                            summation_cnt_x <= summation_cnt_x + 1;
                        else
                            summation_cnt_x <= 0;

                            if summation_cnt_y < kernelsize - 1 then
                                summation_cnt_y <= summation_cnt_y + 1;
                            else
                                summation_cnt_y <= 0;
                                valid_int <= '1';
                            end if;
                        end if;

                        summation_reg <= summation;
                    else
                        valid_int <= '0';
                    end if;
                    
                    valid_reg <= valid_reg(0) & valid_i;
                    --valid_reg <= valid_i;
                end if;
            end if;
        end if;
    end process;

    process(summation_cnt_x, summation_cnt_y, summation_reg)
    begin
        if summation_cnt_x = 0 and summation_cnt_y = 0 then
            summand_B <= (others => '0');
        else
            summand_B <= summation_reg;
        end if;
    end process;

    process(valid_int, stall_i)
    begin
        if valid_int = '1' then
            en <= not stall_i; --stall only if output would be ready and stall_i is true
        else
            en <= '1';
        end if;
    end process;

    valid_o <= valid_int and en;
    en_o <= en;

    patch_val_o <= summation_reg;

end architecture;