library ieee;
use ieee.std_logic_1164.all;

entity pipeline_tb is
end entity;

architecture testbench of pipeline_tb is
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

    component fifo_32x512
    port (
      clk: IN std_logic;
      srst: IN std_logic;
      din: IN std_logic_VECTOR(31 downto 0);
      wr_en: IN std_logic;
      rd_en: IN std_logic;
      dout: OUT std_logic_VECTOR(31 downto 0);
      full: OUT std_logic;
      empty: OUT std_logic);
    end component;

    constant CLK_PERIOD : time := 10 ns;

    --signal clk, rst, valid_i, valid_o, stall_i, en_o : std_logic;
    --signal patch_val, kernel_val, result : std_logic_vector(31 downto 0);

    signal bus_clk, reset_32 : std_logic;

    signal user_w_write_kernel_32_wren :  std_logic;
    signal user_w_write_kernel_32_full :  std_logic;
    signal user_w_write_kernel_32_data :  std_logic_vector(31 DOWNTO 0);
    signal user_w_write_kernel_32_open :  std_logic;
    signal user_w_write_patch_32_wren :  std_logic;
    signal user_w_write_patch_32_full :  std_logic;
    signal user_w_write_patch_32_data :  std_logic_vector(31 DOWNTO 0);
    signal user_w_write_patch_32_open :  std_logic;

    signal user_r_read_32_rden :  std_logic;
    signal user_r_read_32_empty :  std_logic;
    signal user_r_read_32_data :  std_logic_vector(31 DOWNTO 0);
    signal user_r_read_32_eof :  std_logic;
    signal user_r_read_32_open :  std_logic;

    signal rd_en_patch : std_logic;
    signal rd_en_kernel : std_logic;
    signal empty_patch : std_logic;
    signal empty_kernel : std_logic;
    signal wr_en_o : std_logic;
    signal full_o : std_logic;

    signal srcnn_valid_i : std_logic;
    signal srcnn_valid_reg_i : std_logic;
    signal srcnn_valid_o : std_logic;
    signal srcnn_stall_i : std_logic;
    signal srcnn_en_o : std_logic;
    signal patch_data_in : std_logic_vector(31 downto 0);
    signal kernel_data_in : std_logic_vector(31 downto 0);
    signal result : std_logic_vector(31 downto 0);
begin

    dut_pm : patch_mult
    generic map(KERNELSIZE => 3)
    port map(
      clk => bus_clk,
      rst => reset_32,

      valid_i => srcnn_valid_reg_i,
      valid_o => srcnn_valid_o,
      stall_i => srcnn_stall_i,
      en_o => srcnn_en_o,

      patch_val_i => patch_data_in,
      kernel_val_i => kernel_data_in,
      patch_val_o => result
    );

    fifo_32_patch : fifo_32x512
        port map(
        clk        => bus_clk,
        srst       => reset_32,
        din        => user_w_write_patch_32_data,
        wr_en      => user_w_write_patch_32_wren,
        rd_en      => rd_en_patch,
        dout       => patch_data_in,
        full       => user_w_write_patch_32_full,
        empty      => empty_patch
        );

    fifo_32_kernel : fifo_32x512
        port map(
        clk        => bus_clk,
        srst       => reset_32,
        din        => user_w_write_kernel_32_data,
        wr_en      => user_w_write_kernel_32_wren,
        rd_en      => rd_en_kernel,
        dout       => kernel_data_in,
        full       => user_w_write_kernel_32_full,
        empty      => empty_kernel
        );

    fifo_32_out : fifo_32x512
        port map(
        clk        => bus_clk,
        srst       => reset_32,
        din        => result,
        wr_en      => wr_en_o,
        rd_en      => user_r_read_32_rden,
        dout       => user_r_read_32_data,
        full       => full_o,
        empty      => user_r_read_32_empty
        );

    reset_32 <= not (user_w_write_patch_32_open or user_w_write_kernel_32_open or user_r_read_32_open);

    user_r_read_32_eof <= '0';

    -- srcnn pipeline 
    
    srcnn_valid_i <= not (empty_patch or empty_kernel);
    rd_en_patch <= srcnn_valid_i and srcnn_en_o;
    rd_en_kernel <= srcnn_valid_i and srcnn_en_o;
    srcnn_stall_i <= full_o;
    wr_en_o <= srcnn_valid_o;

    --process for flip-flip as FIFOs are not FWFT
    process(reset_32, bus_clk)
    begin
        if reset_32 = '1' then
            srcnn_valid_reg_i <= '0';
        elsif bus_clk'event and bus_clk = '1' then
            if srcnn_en_o = '1' then
            srcnn_valid_reg_i <= srcnn_valid_i;
            end if;
        end if;
    end process;

    ------

    stimulus: process
    begin
        --rst <= '1';
        --valid_i <= '0';
        --stall_i <= '0';
        --patch_val <= (others =>'0');
        --kernel_val <= (others => '0');

        user_w_write_kernel_32_wren <= '0';
        user_w_write_kernel_32_data <= (others => '0');
        user_w_write_kernel_32_open <= '0';
        user_w_write_patch_32_wren <= '0';
        user_w_write_patch_32_data <= (others => '0');
        user_w_write_patch_32_open <= '0';

        user_r_read_32_rden <= '0';
        user_r_read_32_open <= '0';

        wait for 1 ns;
        wait for CLK_PERIOD;

        --rst <= '0';
        user_w_write_kernel_32_open <= '1';
        user_w_write_patch_32_open <= '1';
        user_r_read_32_open <= '1';
        wait for CLK_PERIOD*2;

        --patch_val <= "00000100000000000000000000000000"; --1
        --kernel_val <= "00001000000000000000000000000000"; --2
        user_w_write_patch_32_data <= "00000100000000000000000000000000"; --1
        user_w_write_kernel_32_data <= "00001000000000000000000000000000"; --2
        user_w_write_patch_32_wren <= '1';
        user_w_write_kernel_32_wren <= '0';
        wait for CLK_PERIOD;

        --valid_i <= '1';
        user_w_write_patch_32_wren <= '0';
        user_w_write_kernel_32_wren <= '1';
        wait for CLK_PERIOD;

        --kernel_val <= "00000100000000000000000000000000"; --1
        user_w_write_patch_32_data <= "00000100000000000000000000000000"; --1
        user_w_write_kernel_32_data <= "00000100000000000000000000000000"; --1
        user_w_write_patch_32_wren <= '1';
        user_w_write_kernel_32_wren <= '1';
        wait for CLK_PERIOD*19;
        
        user_w_write_patch_32_wren <= '0';
        user_w_write_kernel_32_wren <= '1';
        wait for CLK_PERIOD*11;
        
        user_r_read_32_rden <= '1';

        --patch_val <= "00001000000000000000000000000000"; --2
        --kernel_val <= "00001000000000000000000000000000"; --2
        --stall_i <= '1';
        --wait for CLK_PERIOD;

        --patch_val <= "00000010000000000000000000000000"; --0.5
        --kernel_val <= "00000010000000000000000000000000"; --0.5
        --stall_i <= '0';
        --wait for CLK_PERIOD;

        --patch_val <= "10000100000000000000000000000000"; --
        --kernel_val <= "10000100000000000000000000000000"; --
        --valid_i <= '0';
        --wait for CLK_PERIOD;

        --patch_val <= "00000100000000000000000000000000"; --1
        --kernel_val <= "00000100000000000000000000000000"; --1
        --valid_i <= '1';
        --wait for CLK_PERIOD;

        --patch_val <= "00000010000000000000000000000000"; --0.5
        --kernel_val <= "00000010000000000000000000000000"; --0.5
        --stall_i <= '1';
        --wait for CLK_PERIOD*6;

        --patch_val <= "00000100000000000000000000000000"; --1
        --kernel_val <= "00000100000000000000000000000000"; --1
        --stall_i <= '0';

        --wait for CLK_PERIOD*10;

        --valid_i <= '0';

        wait;

    end process;

    clk_gen: process
    begin
        bus_clk <= '1';
        wait for CLK_PERIOD/2;
        bus_clk <= '0';
        wait for CLK_PERIOD/2;
    end process;

end architecture;