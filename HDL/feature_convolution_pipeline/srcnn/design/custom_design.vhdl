library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.config_pkg.all;

entity custom_design is
    port(
        -- global
        clk : in std_logic;

        -- config interface
        user_w_config_wren : in std_logic;
        user_w_config_full : out std_logic;
        user_w_config_data : in std_logic_vector(31 DOWNTO 0);
        user_w_config_open : in std_logic;
        user_config_addr :  in std_logic_vector(4 DOWNTO 0);
        user_config_addr_update : in std_logic;

        -- feature stream
        user_w_write_feature_32_wren : in std_logic;
        user_w_write_feature_32_full : out std_logic;
        user_w_write_feature_32_data : in std_logic_vector(31 DOWNTO 0);
        user_w_write_feature_32_open : in std_logic;

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

        -- ready message interface
        --user_r_mem_8_rden : in std_logic;
        --user_r_mem_8_empty : out std_logic;
        --user_r_mem_8_data : out std_logic_vector(7 DOWNTO 0);
        --user_r_mem_8_eof : out std_logic;
        --user_r_mem_8_open : in std_logic
    );
end entity;

architecture archi of custom_design is

    component memory_stage is
        port(
            -- global
            clk : in std_logic;
            reset : in std_logic;
    
            -- config interface
            user_w_config_wren : in std_logic;
            user_w_config_full : out std_logic;
            user_w_config_data : in std_logic_vector(31 DOWNTO 0);
            user_config_addr :  in std_logic_vector(4 DOWNTO 0);
            user_config_addr_update : in std_logic;
    
            -- feature stream
            user_w_write_feature_32_wren : in std_logic;
            user_w_write_feature_32_full : out std_logic;
            user_w_write_feature_32_data : in std_logic_vector(31 DOWNTO 0);
            
            -- kernel stream
            user_w_write_kernel_32_wren : in std_logic;
            user_w_write_kernel_32_full : out std_logic;
            user_w_write_kernel_32_data : in std_logic_vector(31 DOWNTO 0);
    
            -- interface to next stage
            feature_data_o : out std_logic_vector(31 downto 0);
            kernel_data_o : out std_logic_vector(31 downto 0);
            data_valid_o : out std_logic;
            kernelsize_o : out integer range 0 to KERNELSIZE_MAX;
            stall_i : in std_logic
        );
    end component;

    component patch_mult is
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

    signal feature_data : std_logic_vector(31 downto 0);
    signal kernel_data : std_logic_vector(31 downto 0);
    signal result : std_logic_vector(31 downto 0);
    signal mem_data_valid : std_logic;
    signal mult_data_valid : std_logic;
    signal stall_for_mem, en_from_mult : std_logic;
    signal stall_for_mult : std_logic;
    signal kernelsize : integer range 0 to KERNELSIZE_MAX;
begin

    mem_stage_inst : memory_stage
        port map(
            -- global
            clk => clk,
            reset => reset,
    
            -- config interface
            user_w_config_wren => user_w_config_wren,
            user_w_config_full => user_w_config_full,
            user_w_config_data => user_w_config_data,
            user_config_addr => user_config_addr,
            user_config_addr_update => user_config_addr_update,
    
            -- feature stream
            user_w_write_feature_32_wren => user_w_write_feature_32_wren,
            user_w_write_feature_32_full => user_w_write_feature_32_full,
            user_w_write_feature_32_data => user_w_write_feature_32_data,
            
            -- kernel stream
            user_w_write_kernel_32_wren => user_w_write_kernel_32_wren,
            user_w_write_kernel_32_full => user_w_write_kernel_32_full,
            user_w_write_kernel_32_data => user_w_write_kernel_32_data,
    
            -- interface to next stage
            feature_data_o => feature_data,
            kernel_data_o => kernel_data,
            data_valid_o => mem_data_valid,
            kernelsize_o => kernelsize,
            stall_i => stall_for_mem
        );

    patch_mult_inst : patch_mult
        port map(
            clk => clk,
            rst => reset,
    
            kernelsize => kernelsize,
        
            valid_i => mem_data_valid,
            valid_o => mult_data_valid,
            stall_i => stall_for_mult,
            en_o => en_from_mult,
    
            patch_val_i => feature_data,
            kernel_val_i => kernel_data,
            patch_val_o => result
        );

    fifo_32_out : fifo_32x512
        port map(
            clk        => clk,
            srst       => reset,
            din        => result,
            wr_en      => mult_data_valid,
            rd_en      => user_r_read_32_rden,
            dout       => user_r_read_32_data,
            full       => stall_for_mult,
            empty      => user_r_read_32_empty
        );

    -- combinatorial assignments
    stall_for_mem <= not en_from_mult;

    -- reset signals
    reset <= not (user_w_write_feature_32_open or user_w_write_kernel_32_open or user_r_read_32_open or user_w_config_open);

    -- permanent settings
    user_r_read_32_eof <= '0';
    --user_r_mem_8_eof <= '0';

end architecture;