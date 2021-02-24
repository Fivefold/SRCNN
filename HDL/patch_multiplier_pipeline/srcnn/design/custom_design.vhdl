library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity custom_design is
    port(
        -- global
        clk : in std_logic;

        -- patch stream
        user_w_write_patch_32_wren : in std_logic;
        user_w_write_patch_32_full : out std_logic;
        user_w_write_patch_32_data : in std_logic_vector(31 DOWNTO 0);
        user_w_write_patch_32_open : in std_logic;

        -- kernel stream
        user_w_write_kernel_32_wren : in std_logic;
        user_w_write_kernel_32_full : out std_logic;
        user_w_write_kernel_32_data : in std_logic_vector(31 DOWNTO 0);
        user_w_write_kernel_32_open : in std_logic;

        -- output stream
        user_r_read_32_rden : in std_logic;
        user_r_read_32_empty : out std_logic;
        user_r_read_32_data : out std_logic_vector(31 DOWNTO 0);
        user_r_read_32_eof : out std_logic;
        user_r_read_32_open : in std_logic
    );
end entity;

architecture archi of custom_design is

    component patch_mult is
        generic(
            KERNELSIZE : natural := 9
        );
        port(
            clk : in std_logic;
            rst : in std_logic;
        
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

    signal reset : std_logic;

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

    pm_inst0 : patch_mult
        generic map(
            KERNELSIZE => 5
        )
        port map(
            clk => clk,
            rst => reset,
        
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
          clk        => clk,
          srst       => reset,
          din        => user_w_write_patch_32_data,
          wr_en      => user_w_write_patch_32_wren,
          rd_en      => rd_en_patch,
          dout       => patch_data_in,
          full       => user_w_write_patch_32_full,
          empty      => empty_patch
          );
    
    fifo_32_kernel : fifo_32x512
        port map(
          clk        => clk,
          srst       => reset,
          din        => user_w_write_kernel_32_data,
          wr_en      => user_w_write_kernel_32_wren,
          rd_en      => rd_en_kernel,
          dout       => kernel_data_in,
          full       => user_w_write_kernel_32_full,
          empty      => empty_kernel
          );

    fifo_32_out : fifo_32x512
        port map(
            clk        => clk,
            srst       => reset,
            din        => result,
            wr_en      => wr_en_o,
            rd_en      => user_r_read_32_rden,
            dout       => user_r_read_32_data,
            full       => full_o,
            empty      => user_r_read_32_empty
        );

    --process for flip-flip as FIFOs are not FWFT
    process(reset, clk)
    begin
        if reset = '1' then
        srcnn_valid_reg_i <= '0';
        elsif clk'event and clk = '1' then
        if srcnn_en_o = '1' then
            srcnn_valid_reg_i <= srcnn_valid_i;
        end if;
        end if;
    end process;

    -- combinatorial assignments
    srcnn_valid_i <= not (empty_patch or empty_kernel);
    rd_en_patch <= srcnn_valid_i and srcnn_en_o;
    rd_en_kernel <= srcnn_valid_i and srcnn_en_o;
    srcnn_stall_i <= full_o;
    wr_en_o <= srcnn_valid_o;

    -- reset signals
    reset <= not (user_w_write_patch_32_open or user_w_write_kernel_32_open or user_r_read_32_open);

    -- permanent settings
    user_r_read_32_eof <= '0';

end architecture;