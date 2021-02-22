library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.config_pkg.all;

entity memory_stage is
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

        -- command interface
        user_w_command_wren : in std_logic;
        user_w_command_full : out std_logic;
        user_w_command_data : in std_logic_vector(7 DOWNTO 0);
        user_w_command_open : in std_logic;

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
end entity;

architecture archi of memory_stage is
    type feature_mem_t is array(0 to IMG_WIDTH_MAX * IMG_HEIGHT_MAX - 1) of std_logic_vector(31 downto 0);
    type kernel_mem_t is array(0 to KERNELSIZE_MAX * KERNELSIZE_MAX - 1) of std_logic_vector(31 downto 0);
    signal feature_array : feature_mem_t;
    signal kernel_array : kernel_mem_t;

    signal feature_addr : integer range 0 to IMG_WIDTH_MAX * IMG_HEIGHT_MAX - 1;
    signal kernel_addr : integer range 0 to KERNELSIZE_MAX * KERNELSIZE_MAX - 1;
    
    signal image_width : integer range 0 to IMG_WIDTH_MAX;
    signal image_height : integer range 0 to IMG_HEIGHT_MAX;
    signal kernelsize : integer range 0 to KERNELSIZE_MAX;

    signal both_rden : std_logic;
    signal feature_wren, feature_rden : std_logic;
    signal kernel_wren, kernel_rden : std_logic;

    signal kernelfill_done, featurefill_done : std_logic;

    signal feature_fill_cnt_x : integer range 0 to IMG_WIDTH_MAX - 1;
    signal feature_fill_cnt_y : integer range 0 to IMG_HEIGHT_MAX - 1;
    signal feature_fill_cnt : integer range 0 to IMG_WIDTH_MAX * IMG_HEIGHT_MAX - 1;
    signal kernel_fill_cnt_x : integer range 0 to KERNELSIZE_MAX - 1;
    signal kernel_fill_cnt_y : integer range 0 to KERNELSIZE_MAX - 1;
    signal kernel_fill_cnt : integer range 0 to KERNELSIZE_MAX * KERNELSIZE_MAX - 1;

    signal feature_read_addr : integer range 0 to IMG_WIDTH_MAX * IMG_HEIGHT_MAX - 1;
    signal kernel_read_addr : integer range 0 to KERNELSIZE_MAX * KERNELSIZE_MAX - 1;
    signal feature_bkp, kernel_bkp : std_logic_vector(31 downto 0);
    signal data_valid, data_valid_bkp : std_logic;
    signal feature_data : std_logic_vector(31 downto 0);
    signal kernel_data : std_logic_vector(31 downto 0);
    signal stall_reg : std_logic;
    
    signal pixel_x_sig : integer range 0 to IMG_WIDTH_MAX - 1;
    signal pixel_y_sig : integer range 0 to IMG_HEIGHT_MAX - 1;
    signal pixel_cnt_sig : integer range 0 to IMG_WIDTH_MAX * IMG_HEIGHT_MAX - 1;
    signal kernel_x_sig : integer range - KERNELSIZE_MAX/2 to KERNELSIZE_MAX/2;
    signal kernel_y_sig : integer range - KERNELSIZE_MAX/2 to KERNELSIZE_MAX/2;
    signal feature_x_sig : integer range - KERNELSIZE_MAX/2  to IMG_WIDTH_MAX + KERNELSIZE_MAX/2;
    signal feature_y_sig : integer range - KERNELSIZE_MAX/2  to IMG_HEIGHT_MAX + KERNELSIZE_MAX/2;
    signal kernel_center_sig : integer range 0 to KERNELSIZE_MAX * KERNELSIZE_MAX - 1;
    signal feature_ypos_xhalf_sig : integer range 0 to IMG_WIDTH_MAX * IMG_HEIGHT_MAX - 1;
    signal kernel_ypos_xhalf_sig : integer range 0 to KERNELSIZE_MAX * KERNELSIZE_MAX - 1;

begin

    -- save data from config interface
    config_proc : process(clk)
    begin
        if reset = '1' then
            image_width <= 1;
            image_height <= 1;
            kernelsize <= 3;
        elsif clk'event and clk = '1' then
            if user_w_config_wren = '1' then
                case user_config_addr is
                    when "00000" =>
                        image_width <= to_integer(unsigned(user_w_config_data));
                    when "00001" =>
                        image_height <= to_integer(unsigned(user_w_config_data));
                    when "00010" =>
                        kernelsize <= to_integer(unsigned(user_w_config_data(3 downto 0)));
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    -- inferred feature RAM
    process (clk)
    begin
        if clk'event and clk = '1' then
            if feature_wren = '1' then 
                feature_array(feature_addr) <= user_w_write_feature_32_data;
            end if;
            if feature_rden = '1' then
                feature_data <= feature_array(feature_addr);
            end if;
        end if;
    end process;

    -- inferred kernel RAM
    process (clk)
    begin
        if clk'event and clk = '1' then
            if kernel_wren = '1' then 
                kernel_array(kernel_addr) <= user_w_write_kernel_32_data;
            end if;
            if kernel_rden = '1' then
                kernel_data <= kernel_array(kernel_addr);
            end if;
        end if;
    end process;

    -- memory addressing logic

    process(reset, clk)
        variable pixel_x : integer range 0 to IMG_WIDTH_MAX - 1;
        variable pixel_y : integer range 0 to IMG_HEIGHT_MAX - 1;
        variable pixel_cnt : integer range 0 to IMG_WIDTH_MAX * IMG_HEIGHT_MAX - 1;
        variable kernel_x : integer range - KERNELSIZE_MAX/2 to KERNELSIZE_MAX/2;
        variable kernel_y : integer range - KERNELSIZE_MAX/2 to KERNELSIZE_MAX/2;
        variable feature_x : integer range - KERNELSIZE_MAX/2  to IMG_WIDTH_MAX + KERNELSIZE_MAX/2;
        variable feature_y : integer range - KERNELSIZE_MAX/2  to IMG_HEIGHT_MAX + KERNELSIZE_MAX/2;
        variable feature_ypos_xhalf : integer range 0 to IMG_WIDTH_MAX * IMG_HEIGHT_MAX - 1;
        variable kernel_center : integer range 0 to KERNELSIZE_MAX * KERNELSIZE_MAX - 1;
        variable kernel_ypos_xhalf : integer range 0 to KERNELSIZE_MAX * KERNELSIZE_MAX - 1;

        variable skip_feature_retransmission : std_logic;
    begin
        if reset = '1' then
            -- status flags
            kernelfill_done <= '0';
            featurefill_done <= '0';
            skip_feature_retransmission := '0';
            -- memory write
            feature_fill_cnt_x <= 0;
            feature_fill_cnt_y <= 0;
            feature_fill_cnt <= 0;
            feature_ypos_xhalf := 0;
            kernel_fill_cnt_x <= 0;
            kernel_fill_cnt_y <= 0;
            kernel_fill_cnt <= 0;
            kernel_center := 4;
            kernel_ypos_xhalf := 4;
            -- memory read
            data_valid <= '0';
            stall_reg <= '0';
            feature_bkp <= (others => '0');
            kernel_bkp <= (others => '0');
        elsif clk'event and clk = '1' then
            stall_reg <= stall_i;

            if stall_i = '0' then
                data_valid_bkp <= data_valid;
                data_valid <= both_rden;
            else
                data_valid <= data_valid_bkp;
            end if;

            if stall_i = '1' and stall_reg = '0' then
                feature_bkp <= feature_data;
                kernel_bkp <= kernel_data;
            end if;

            -- listen on command interface
            if user_w_command_wren = '1' then
                if user_w_command_data = "00000001" then
                    skip_feature_retransmission := '1'; -- cancel feature retransmission
                end if;
            end if;

            -- synchronous feature memory fill logic
            if feature_wren = '1' and skip_feature_retransmission = '0' then

                feature_fill_cnt <= feature_fill_cnt + 1;
                if feature_fill_cnt_x >= image_width - 1 then
                    feature_fill_cnt_x <= 0;

                    if feature_fill_cnt_y >= image_height -1 then
                        feature_fill_cnt_y <= 0;
                        feature_fill_cnt <= 0;
                        featurefill_done <= '1';
                    else
                        feature_fill_cnt_y <= feature_fill_cnt_y + 1;
                    end if;
                else
                    feature_fill_cnt_x <= feature_fill_cnt_x + 1;
                end if;
            end if;

            -- synchronous kernel memory fill logic
            if kernel_wren = '1' then

                kernel_fill_cnt <= kernel_fill_cnt + 1;
                if kernel_fill_cnt_x >= kernelsize - 1 then
                    kernel_fill_cnt_x <= 0;

                    if kernel_fill_cnt_y >= kernelsize -1 then
                        kernel_fill_cnt_y <= 0;
                        kernel_fill_cnt <= 0;
                        kernelfill_done <= '1';

                        --save address of kernel center
                        kernel_center := kernel_fill_cnt/2;
                        kernel_ypos_xhalf := kernel_center;
                        kernel_read_addr <= kernel_ypos_xhalf;
                    else
                        kernel_fill_cnt_y <= kernel_fill_cnt_y + 1;
                    end if;
                else
                    kernel_fill_cnt_x <= kernel_fill_cnt_x + 1;
                end if;
            end if;

            --we can start to read from memory
            if stall_i = '0' then --and stall_reg = '0'
                if featurefill_done = '1' and kernelfill_done = '1' then

                    -- counting and padding logic

                    if kernel_x <= -kernelsize/2 then
                        kernel_x := 1;
                        kernel_read_addr <= kernel_ypos_xhalf + 1;

                        feature_x := kernel_x + pixel_x;
                        if feature_x < image_width then
                            feature_read_addr <= feature_ypos_xhalf + 1;
                        else
                            feature_read_addr <= feature_ypos_xhalf;
                        end if;
                    elsif kernel_x <= 0 then
                        kernel_x := kernel_x - 1;
                        kernel_read_addr <= kernel_read_addr - 1;

                        feature_x := kernel_x + pixel_x;
                        if feature_x >= 0 then
                            feature_read_addr <= feature_read_addr - 1;
                        end if;
                    elsif kernel_x < kernelsize/2 then
                        kernel_x := kernel_x + 1;
                        kernel_read_addr <= kernel_read_addr + 1;

                        feature_x := kernel_x + pixel_x;
                        if feature_x < image_width then
                            feature_read_addr <= feature_read_addr + 1;
                        end if;
                    else
                        kernel_x := 0;

                        if kernel_y <= -kernelsize/2 then
                            kernel_y := 1;
                            kernel_ypos_xhalf := kernel_center + kernelsize;

                            feature_y := kernel_y + pixel_y;
                            if feature_y < image_height then
                                feature_ypos_xhalf := pixel_cnt + image_width;
                            else
                                feature_ypos_xhalf := pixel_cnt;
                            end if;
                        elsif kernel_y <= 0 then
                            kernel_y := kernel_y - 1;
                            kernel_ypos_xhalf := kernel_ypos_xhalf - kernelsize;

                            feature_y := kernel_y + pixel_y;
                            if feature_y >= 0 then
                                feature_ypos_xhalf := feature_ypos_xhalf - image_width;
                            end if;
                        elsif kernel_y < kernelsize/2 then
                            kernel_y := kernel_y + 1;
                            kernel_ypos_xhalf := kernel_ypos_xhalf + kernelsize;

                            feature_y := kernel_y + pixel_y;
                            if feature_y < image_height then
                                feature_ypos_xhalf := feature_ypos_xhalf + image_width;
                            end if;
                        else
                            kernel_y := 0;
                            pixel_cnt := pixel_cnt + 1;

                            if pixel_x >= image_width - 1 then
                                pixel_x := 0;
            
                                if pixel_y >= image_height - 1 then
                                    pixel_y := 0;
                                    pixel_cnt := 0;
                                    
                                    --readout_done <= '1';
                                    featurefill_done <= '0';
                                    kernelfill_done <= '0';
                                else
                                    pixel_y := pixel_y + 1;
                                end if;
                            else
                                pixel_x := pixel_x + 1;
                            end if;

                            feature_ypos_xhalf := pixel_cnt;
                            kernel_ypos_xhalf := kernel_center;
                        end if;

                        feature_read_addr <= feature_ypos_xhalf;
                        kernel_read_addr <= kernel_ypos_xhalf;
                    end if;
                else
                    pixel_x := 0;
                    pixel_y := 0;
                    pixel_cnt := 0;
                    kernel_x := 0;
                    kernel_y := 0;
                    feature_x := 0;
                    feature_y := 0;
                    feature_read_addr <= 0;
                    feature_ypos_xhalf := 0;
                    kernel_ypos_xhalf := kernel_center;
                    kernel_read_addr <= kernel_ypos_xhalf;
                end if;
            end if;

            -- feature retransmission cancellation
            if featurefill_done = '0' and skip_feature_retransmission = '1' and feature_fill_cnt = 0 then
                skip_feature_retransmission := '0';
                featurefill_done <= '1';
            end if;

        end if;

        -- necessary signals
        user_w_command_full <= skip_feature_retransmission;

        -- signals for simulation
        pixel_x_sig <= pixel_x;
        pixel_y_sig <= pixel_y;
        pixel_cnt_sig <= pixel_cnt;
        kernel_x_sig <= kernel_x;
        kernel_y_sig <= kernel_y;
        feature_x_sig <= feature_x;
        feature_y_sig <= feature_y;
        kernel_center_sig <= kernel_center;
        feature_ypos_xhalf_sig <= feature_ypos_xhalf;
        kernel_ypos_xhalf_sig <= kernel_ypos_xhalf;
    end process;

    process(stall_reg, feature_data, feature_bkp)
    begin
        if stall_reg = '1' then
            feature_data_o <= feature_bkp;
        else
            feature_data_o <= feature_data;
        end if;
    end process;

    process(stall_reg, kernel_data, kernel_bkp)
    begin
        if stall_reg = '1' then
            kernel_data_o <= kernel_bkp;
        else
            kernel_data_o <= kernel_data;
        end if;
    end process;

    process(featurefill_done, kernelfill_done)
    begin
        if featurefill_done = '1' and kernelfill_done = '1' then
            both_rden <= '1';
        else
            both_rden <= '0';
        end if;
    end process;

    --address mux
    process(featurefill_done, kernelfill_done, feature_read_addr, kernel_read_addr, feature_fill_cnt, kernel_fill_cnt)
    begin
        if featurefill_done = '1' and kernelfill_done = '1' then
            feature_addr <= feature_read_addr;
            kernel_addr <= kernel_read_addr;
        else
            feature_addr <= feature_fill_cnt;
            kernel_addr <= kernel_fill_cnt;
        end if;
    end process;

    -- feature wren mux
    process(featurefill_done, user_w_write_feature_32_wren)
    begin
        if featurefill_done = '0' then
            feature_wren <= user_w_write_feature_32_wren;
        else
            feature_wren <= '0';
        end if;
    end process;

    -- kernel wren mux
    process(kernelfill_done, user_w_write_kernel_32_wren)
    begin
        if kernelfill_done = '0' then
            kernel_wren <= user_w_write_kernel_32_wren;
        else
            kernel_wren <= '0';
        end if;
    end process;

    -- permanent connections
    user_w_write_feature_32_full <= featurefill_done;
    user_w_write_kernel_32_full <= kernelfill_done;
    feature_rden <= both_rden;
    kernel_rden <= both_rden;
    kernelsize_o <= kernelsize;
    data_valid_o <= data_valid;

    -- permanent signals
    user_w_config_full <= '0';

end architecture;