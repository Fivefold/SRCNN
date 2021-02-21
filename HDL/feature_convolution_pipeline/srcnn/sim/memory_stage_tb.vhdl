library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.config_pkg.all;

entity memory_stage_tb is
end entity;

architecture testbench of memory_stage_tb is
    constant CLK_PERIOD : time := 10 ns;

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

    function int2fp(number : integer range -32 to 31)
    return std_logic_vector is
        variable vector : std_logic_vector(31 downto 0);
    begin
        vector := (others => '0');
        vector(31 downto 26) := std_logic_vector(to_signed(number, 6));
    return vector;
    end int2fp;

    function fp2int(vector : std_logic_vector(31 downto 0))
    return integer is
        variable number : integer range -32 to 31;
    begin
        number := to_integer(signed(vector(31 downto 26)));
    return number;
    end fp2int;

    constant kernelsize_test : integer := 3;
    constant image_width_test : integer := 2;
    constant image_height_test : integer := 2;
    type array_kernel_t is array (0 to kernelsize_test * kernelsize_test - 1) of integer;
    type array_feature_t is array (0 to image_width_test * image_height_test - 1) of integer;

    -- global
    signal clk : std_logic;
    signal reset : std_logic;

    -- config interface
    signal user_w_config_wren : std_logic;
    signal user_w_config_full : std_logic;
    signal user_w_config_data : std_logic_vector(31 DOWNTO 0);
    signal user_config_addr :  std_logic_vector(4 DOWNTO 0);
    signal user_config_addr_update : std_logic;

    -- feature stream
    signal user_w_write_feature_32_wren : std_logic;
    signal user_w_write_feature_32_full : std_logic;
    signal user_w_write_feature_32_data : std_logic_vector(31 DOWNTO 0);
    
    -- kernel stream
    signal user_w_write_kernel_32_wren : std_logic;
    signal user_w_write_kernel_32_full : std_logic;
    signal user_w_write_kernel_32_data : std_logic_vector(31 DOWNTO 0);

    -- interface to next stage
    signal feature_data_o : std_logic_vector(31 downto 0);
    signal kernel_data_o : std_logic_vector(31 downto 0);
    signal data_valid_o : std_logic;
    signal kernelsize_o : integer range 0 to KERNELSIZE_MAX;
    signal stall_i : std_logic;

    -- register all sync dut inputs (waveform becomes more readable)
    signal user_w_config_wren_reg : std_logic;
    signal user_w_config_data_reg : std_logic_vector(31 DOWNTO 0);
    signal user_config_addr_reg :  std_logic_vector(4 DOWNTO 0);

    signal user_w_write_feature_32_wren_reg : std_logic;
    signal user_w_write_feature_32_data_reg : std_logic_vector(31 DOWNTO 0);

    signal user_w_write_kernel_32_wren_reg : std_logic;
    signal user_w_write_kernel_32_data_reg : std_logic_vector(31 DOWNTO 0);
    signal stall_reg : std_logic;
    
--    procedure write_feature(
--        f : array_feature_t
--    ) is
--        variable k : integer;
--    begin
--        user_w_write_feature_32_wren <= '1';

--        for k in 0 to image_width_test * image_height_test - 1 loop
--            user_w_write_feature_32_data <= int2fp(f(k));
--            wait for CLK_PERIOD;
--        end loop;

--        user_w_write_feature_32_wren <= '0';
--    end write_feature;

--    procedure write_kernel(
--        f : array_kernel_t
--    ) is
--        variable k : integer;
--    begin
--        user_w_write_kernel_32_wren <= '1';

--        for k in 0 to kernelsize_test * kernelsize_test - 1 loop
--            user_w_write_kernel_32_data <= int2fp(f(k));
--            wait for CLK_PERIOD;
--        end loop;

--        user_w_write_kernel_32_wren <= '0';
--    end write_kernel;

begin

    dut : memory_stage
        port map(
            -- global
            clk => clk,
            reset => reset,
    
            -- config interface
            user_w_config_wren => user_w_config_wren_reg,
            user_w_config_full => user_w_config_full,
            user_w_config_data => user_w_config_data_reg,
            user_config_addr => user_config_addr_reg,
            user_config_addr_update => user_config_addr_update,
    
            -- feature stream
            user_w_write_feature_32_wren => user_w_write_feature_32_wren_reg,
            user_w_write_feature_32_full => user_w_write_feature_32_full,
            user_w_write_feature_32_data => user_w_write_feature_32_data_reg,
            
            -- kernel stream
            user_w_write_kernel_32_wren => user_w_write_kernel_32_wren_reg,
            user_w_write_kernel_32_full => user_w_write_kernel_32_full,
            user_w_write_kernel_32_data => user_w_write_kernel_32_data_reg,
    
            -- interface to next stage
            feature_data_o => feature_data_o,
            kernel_data_o => kernel_data_o,
            data_valid_o => data_valid_o,
            kernelsize_o => kernelsize_o,
            stall_i => stall_reg
        );

    clk_gen: process
    begin
        clk <= '1';
        wait for CLK_PERIOD/2;
        clk <= '0';
        wait for CLK_PERIOD/2;
    end process;

    sync_inputs: process(reset, clk)
    begin 
        if reset = '1' then
            user_w_config_wren_reg <= '0';
            user_w_config_data_reg <= (others => '0');
            user_config_addr_reg <= (others => '0');

            user_w_write_feature_32_wren_reg <= '0';
            user_w_write_feature_32_data_reg <= (others => '0');

            user_w_write_kernel_32_wren_reg <= '0';
            user_w_write_kernel_32_data_reg <= (others => '0');
            stall_reg <= '0';
        elsif rising_edge(clk) then
            user_w_config_wren_reg <= user_w_config_wren;
            user_w_config_data_reg <= user_w_config_data;
            user_config_addr_reg <= user_config_addr;

            user_w_write_feature_32_wren_reg <= user_w_write_feature_32_wren;
            user_w_write_feature_32_data_reg <= user_w_write_feature_32_data;

            user_w_write_kernel_32_wren_reg <= user_w_write_kernel_32_wren;
            user_w_write_kernel_32_data_reg <= user_w_write_kernel_32_data;
            stall_reg <= stall_i;
        end if;
    end process;

    stimuli : process
        variable array_kernel : array_kernel_t;
        variable array_feature : array_feature_t;
        variable k : integer;
    begin
        reset <= '1';

        user_w_config_wren <= '0';
        user_w_config_data <= (others => '0');
        user_config_addr <= (others => '0');
        user_w_write_feature_32_wren <= '0';
        user_w_write_feature_32_data <= (others => '0');
        user_w_write_kernel_32_wren <= '0';
        user_w_write_kernel_32_data <= (others => '0');
        stall_i <= '0';

        wait for CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD * 2;

        user_config_addr <= "00000";
        user_w_config_data <= std_logic_vector(to_unsigned(image_width_test, 32));
        user_w_config_wren <= '1';
        wait for CLK_PERIOD;
        user_config_addr <= "00001";
        user_w_config_data <= std_logic_vector(to_unsigned(image_height_test, 32));
        user_w_config_wren <= '1';
        wait for CLK_PERIOD;
        user_config_addr <= "00010";
        user_w_config_data <= std_logic_vector(to_unsigned(kernelsize_test, 32));
        user_w_config_wren <= '1';
        wait for CLK_PERIOD;
        user_w_config_wren <= '0';
        wait for CLK_PERIOD;

        --write_feature((1,2,3,4));
        --write_kernel((1,2,3,4,5,6,7,8,9));
        
        array_feature := (1,2,3,4);
        array_kernel := (1,2,3,4,5,6,7,8,9);

        user_w_write_feature_32_wren <= '1';
        for k in 0 to image_width_test * image_height_test - 1 loop
            user_w_write_feature_32_data <= int2fp(array_feature(k));
            wait for CLK_PERIOD;
        end loop;
        user_w_write_feature_32_wren <= '0';

        user_w_write_kernel_32_wren <= '1';
        for k in 0 to kernelsize_test * kernelsize_test - 1 loop
            user_w_write_kernel_32_data <= int2fp(array_kernel(k));
            wait for CLK_PERIOD;
        end loop;
        user_w_write_kernel_32_wren <= '0';
        
        wait for CLK_PERIOD * 5;
        stall_i <= '1';
        wait for CLK_PERIOD * 2;
        stall_i <= '0';
        wait for CLK_PERIOD * 31; --on user_w_write_kernel_32_full; --until user_w_write_kernel_32_full = '0';
        stall_i <= '1';
        wait for CLK_PERIOD;
        stall_i <= '0';
        
        

        wait;

    end process;

end architecture;