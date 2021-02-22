library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity design_tb is
end entity;

architecture archi of design_tb is
    constant CLK_PERIOD : time := 10 ns;

    component custom_design is
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
    
            -- command interface
            user_w_command_wren : in std_logic;
            user_w_command_full : out std_logic;
            user_w_command_data : in std_logic_vector(7 DOWNTO 0);
            user_w_command_open : in std_logic;
    
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
        );
    end component;

    -- clock
    signal clk :  std_logic;

    -- command interface
    signal user_w_command_wren :  std_logic;
    signal user_w_command_full :  std_logic;
    signal user_w_command_data :  std_logic_vector(7 DOWNTO 0);
    signal user_w_command_open :  std_logic;

    -- config interface
    signal user_w_config_wren :  std_logic;
    signal user_w_config_full :  std_logic;
    signal user_w_config_data :  std_logic_vector(31 DOWNTO 0);
    signal user_w_config_open :  std_logic;
    signal user_config_addr :  std_logic_vector(4 DOWNTO 0);
    signal user_config_addr_update :  std_logic;

    -- output stream
    signal user_r_read_32_rden :  std_logic;
    signal user_r_read_32_empty :  std_logic;
    signal user_r_read_32_data :  std_logic_vector(31 DOWNTO 0);
    signal user_r_read_32_eof :  std_logic;
    signal user_r_read_32_open :  std_logic;

    -- feature stream
    signal user_w_write_feature_32_wren :  std_logic;
    signal user_w_write_feature_32_full :  std_logic;
    signal user_w_write_feature_32_data :  std_logic_vector(31 DOWNTO 0);
    signal user_w_write_feature_32_open :  std_logic;

    -- kernel stream
    signal user_w_write_kernel_32_wren :  std_logic;
    signal user_w_write_kernel_32_full :  std_logic;
    signal user_w_write_kernel_32_data :  std_logic_vector(31 DOWNTO 0);
    signal user_w_write_kernel_32_open :  std_logic;

begin

    design_inst : custom_design
        port map(
            -- global
            clk => clk,
    
            -- config interface
            user_w_config_wren => user_w_config_wren,
            user_w_config_full => user_w_config_full,
            user_w_config_data => user_w_config_data,
            user_w_config_open => user_w_config_open,
            user_config_addr => user_config_addr,
            user_config_addr_update => user_config_addr_update,

            -- command interface
            user_w_command_wren => user_w_command_wren,
            user_w_command_full => user_w_command_full,
            user_w_command_data => user_w_command_data,
            user_w_command_open => user_w_command_open,
    
            -- feature stream
            user_w_write_feature_32_wren => user_w_write_feature_32_wren,
            user_w_write_feature_32_full => user_w_write_feature_32_full,
            user_w_write_feature_32_data => user_w_write_feature_32_data,
            user_w_write_feature_32_open => user_w_write_feature_32_open,
            
            -- kernel stream
            user_w_write_kernel_32_wren => user_w_write_kernel_32_wren,
            user_w_write_kernel_32_full => user_w_write_kernel_32_full,
            user_w_write_kernel_32_data => user_w_write_kernel_32_data,
            user_w_write_kernel_32_open => user_w_write_kernel_32_open,
    
            -- output stream
            user_r_read_32_rden => user_r_read_32_rden,
            user_r_read_32_empty => user_r_read_32_empty,
            user_r_read_32_data => user_r_read_32_data,
            user_r_read_32_eof => user_r_read_32_eof,
            user_r_read_32_open => user_r_read_32_open
        );

    clk_gen: process
    begin
        clk <= '1';
        wait for CLK_PERIOD/2;
        clk <= '0';
        wait for CLK_PERIOD/2;
    end process;

    config_proc: process
    begin
        user_w_config_wren <= '0';
        user_w_config_data <= (others => '0');
        user_config_addr <= (others => '0');
        user_config_addr_update <= '0';
        user_w_config_open <= '0';
        wait for CLK_PERIOD;

        user_w_config_open <= '1';
        wait for CLK_PERIOD;

        user_config_addr <= "00000"; --image_width
        user_w_config_data <= std_logic_vector(to_unsigned(2, 32));--256
        user_w_config_wren <= '1';
        wait for CLK_PERIOD;

        user_config_addr <= "00001"; --image_height
        user_config_addr_update <= '1';
        user_w_config_data <= std_logic_vector(to_unsigned(2, 32));--256
        user_w_config_wren <= '1';
        wait for CLK_PERIOD;

        user_config_addr <= "00010"; -- kernelsize
        user_config_addr_update <= '1';
        user_w_config_data <= std_logic_vector(to_unsigned(3, 32));--5
        user_w_config_wren <= '1';
        wait for CLK_PERIOD;

        user_config_addr <= "00010";
        user_config_addr_update <= '0';
        user_w_config_data <= (others => '0');
        user_w_config_wren <= '0';
        wait for CLK_PERIOD;

        wait;
    end process;


    input_proc: process
        variable line_input : line;
        file input_file : text;
        variable slv_input : std_logic_vector(31 downto 0);
    begin
        user_w_write_feature_32_open <= '0';
        user_w_write_feature_32_wren <= '0';
        user_w_write_feature_32_data <= (others => '0');
        wait for CLK_PERIOD * 8;

        user_w_write_feature_32_open <= '1';
        wait for CLK_PERIOD;

        file_open(input_file, "C:\Users\phili\projects\SRCNN_bpk\new\xillinux-eval-zedboard-2.0c_v6_sim\srcnn\sim\input.txt", read_mode);

        while not endfile(input_file) loop
            readline(input_file, line_input);
            hread(line_input, slv_input);

            --report "slv_input: " & to_hstring(slv_input);

            if user_w_write_feature_32_full /= '0' then
                wait until user_w_write_feature_32_full = '0';
            end if;
            user_w_write_feature_32_wren <= '1';
            user_w_write_feature_32_data <= slv_input;
            wait for CLK_PERIOD;
            user_w_write_feature_32_wren <= '0';

        end loop;
        file_close(input_file);
        user_w_write_feature_32_open <= '0';
        wait;
    end process;


    kernel_proc: process
        variable line_kernel : line;
        file kernel_file : text;
        variable slv_kernel : std_logic_vector(31 downto 0);
    begin
        user_w_write_kernel_32_open <= '0';
        user_w_write_kernel_32_wren <= '0';
        user_w_write_kernel_32_data <= (others => '0');
        wait for CLK_PERIOD * 8;

        user_w_write_kernel_32_open <= '1';
        wait for CLK_PERIOD;

        file_open(kernel_file, "C:\Users\phili\projects\SRCNN_bpk\new\xillinux-eval-zedboard-2.0c_v6_sim\srcnn\sim\kernel.txt", read_mode);

        while not endfile(kernel_file) loop
            readline(kernel_file, line_kernel);
            hread(line_kernel, slv_kernel);

            --report "slv_kernel: " & to_hstring(slv_kernel);

            if user_w_write_kernel_32_full /= '0' then
                wait until user_w_write_kernel_32_full = '0';
            end if;
            user_w_write_kernel_32_wren <= '1';
            user_w_write_kernel_32_data <= slv_kernel;
            wait for CLK_PERIOD;
            user_w_write_kernel_32_wren <= '0';

        end loop;
        file_close(kernel_file);
        user_w_write_kernel_32_open <= '0';
        wait;
    end process;



    read_proc: process
        variable line_output : line;
        file output_file : text;
        variable slv_output : std_logic_vector(31 downto 0);
    begin
        user_r_read_32_open <= '0';
        user_r_read_32_rden <= '0';
        user_r_read_32_data <= (others => '0');
        wait for CLK_PERIOD * 10;

        user_r_read_32_open <= '1';
        wait for CLK_PERIOD;

        file_open(output_file, "C:\Users\phili\projects\SRCNN_bpk\new\xillinux-eval-zedboard-2.0c_v6_sim\srcnn\sim\output.txt", read_mode);

        while not endfile(output_file) loop
            readline(output_file, line_output);
            hread(line_output, slv_output);

            report "slv_output: " & to_hstring(slv_output);

            if user_r_read_32_empty /= '0' then
                wait until user_r_read_32_empty = '0';
            end if;
            user_r_read_32_rden <= '1';
            wait for CLK_PERIOD;
            assert user_w_write_kernel_32_data = slv_output report "byte error!";
            user_r_read_32_rden <= '0';

        end loop;
        report "simulation done";
        file_close(output_file);
        user_r_read_32_open <= '0';
        wait;
    end process;

end architecture;