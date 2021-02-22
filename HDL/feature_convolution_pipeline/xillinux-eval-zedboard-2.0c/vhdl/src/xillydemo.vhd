library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity xillydemo is
  port (
    -- For Vivado, delete the port declarations for PS_CLK, PS_PORB and
    -- PS_SRSTB, and uncomment their declarations as signals further below.

    --PS_CLK : IN std_logic;
    --PS_PORB : IN std_logic;
    --PS_SRSTB : IN std_logic;
    clk_100 : IN std_logic;
    otg_oc : IN std_logic;
    PS_GPIO : INOUT std_logic_vector(55 DOWNTO 0);
    GPIO_LED : OUT std_logic_vector(3 DOWNTO 0);
    vga4_blue : OUT std_logic_vector(3 DOWNTO 0);
    vga4_green : OUT std_logic_vector(3 DOWNTO 0);
    vga4_red : OUT std_logic_vector(3 DOWNTO 0);
    vga_hsync : OUT std_logic;
    vga_vsync : OUT std_logic;
    audio_mclk : OUT std_logic;
    audio_dac : OUT std_logic;
    audio_adc : IN std_logic;
    audio_bclk : IN std_logic;
    audio_lrclk : IN std_logic;
    smb_sclk : OUT std_logic;
    smb_sdata : INOUT std_logic;
    smbus_addr : OUT std_logic_vector(1 DOWNTO 0));
  end xillydemo;

architecture sample_arch of xillydemo is
  component xillybus
    port (
      PS_CLK : IN std_logic;
      PS_PORB : IN std_logic;
      PS_SRSTB : IN std_logic;
      clk_100 : IN std_logic;
      otg_oc : IN std_logic;
      DDR_Addr : INOUT std_logic_vector(14 DOWNTO 0);
      DDR_BankAddr : INOUT std_logic_vector(2 DOWNTO 0);
      DDR_CAS_n : INOUT std_logic;
      DDR_CKE : INOUT std_logic;
      DDR_CS_n : INOUT std_logic;
      DDR_Clk : INOUT std_logic;
      DDR_Clk_n : INOUT std_logic;
      DDR_DM : INOUT std_logic_vector(3 DOWNTO 0);
      DDR_DQ : INOUT std_logic_vector(31 DOWNTO 0);
      DDR_DQS : INOUT std_logic_vector(3 DOWNTO 0);
      DDR_DQS_n : INOUT std_logic_vector(3 DOWNTO 0);
      DDR_DRSTB : INOUT std_logic;
      DDR_ODT : INOUT std_logic;
      DDR_RAS_n : INOUT std_logic;
      DDR_VRN : INOUT std_logic;
      DDR_VRP : INOUT std_logic;
      MIO : INOUT std_logic_vector(53 DOWNTO 0);
      PS_GPIO : INOUT std_logic_vector(55 DOWNTO 0);
      DDR_WEB : OUT std_logic;
      GPIO_LED : OUT std_logic_vector(3 DOWNTO 0);
      bus_clk : OUT std_logic;
      quiesce : OUT std_logic;
      vga4_blue : OUT std_logic_vector(3 DOWNTO 0);
      vga4_green : OUT std_logic_vector(3 DOWNTO 0);
      vga4_red : OUT std_logic_vector(3 DOWNTO 0);
      vga_hsync : OUT std_logic;
      vga_vsync : OUT std_logic;
      user_w_command_wren : OUT std_logic;
      user_w_command_full : IN std_logic;
      user_w_command_data : OUT std_logic_vector(7 DOWNTO 0);
      user_w_command_open : OUT std_logic;
      user_w_config_wren : OUT std_logic;
      user_w_config_full : IN std_logic;
      user_w_config_data : OUT std_logic_vector(31 DOWNTO 0);
      user_w_config_open : OUT std_logic;
      user_config_addr : OUT std_logic_vector(4 DOWNTO 0);
      user_config_addr_update : OUT std_logic;
      user_r_read_32_rden : OUT std_logic;
      user_r_read_32_empty : IN std_logic;
      user_r_read_32_data : IN std_logic_vector(31 DOWNTO 0);
      user_r_read_32_eof : IN std_logic;
      user_r_read_32_open : OUT std_logic;
      user_w_write_feature_32_wren : OUT std_logic;
      user_w_write_feature_32_full : IN std_logic;
      user_w_write_feature_32_data : OUT std_logic_vector(31 DOWNTO 0);
      user_w_write_feature_32_open : OUT std_logic;
      user_w_write_kernel_32_wren : OUT std_logic;
      user_w_write_kernel_32_full : IN std_logic;
      user_w_write_kernel_32_data : OUT std_logic_vector(31 DOWNTO 0);
      user_w_write_kernel_32_open : OUT std_logic;
      user_clk : OUT std_logic;
      user_wren : OUT std_logic;
      user_rden : OUT std_logic;
      user_wstrb : OUT std_logic_vector(3 DOWNTO 0);
      user_addr : OUT std_logic_vector(31 DOWNTO 0);
      user_rd_data : IN std_logic_vector(31 DOWNTO 0);
      user_wr_data : OUT std_logic_vector(31 DOWNTO 0);
      user_irq : IN std_logic);
  end component;

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

-- Synplicity black box declaration
  --attribute syn_black_box : boolean;
  --attribute syn_black_box of fifo_32x512: component is true;
  --attribute syn_black_box of fifo_8x2048: component is true;

  type demo_mem is array(0 TO 31) of std_logic_vector(7 DOWNTO 0);
  signal litearray0 : demo_mem;
  signal litearray1 : demo_mem;
  signal litearray2 : demo_mem;
  signal litearray3 : demo_mem;
  signal lite_addr : integer range 0 to 31;

  signal quiesce : std_logic;

  -- clock
  signal bus_clk :  std_logic;

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

  -- xillybus lite
  signal user_clk :  std_logic;
  signal user_wren :  std_logic;
  signal user_rden :  std_logic;
  signal user_wstrb :  std_logic_vector(3 DOWNTO 0);
  signal user_addr :  std_logic_vector(31 DOWNTO 0);
  signal user_rd_data :  std_logic_vector(31 DOWNTO 0);
  signal user_wr_data :  std_logic_vector(31 DOWNTO 0);
  signal user_irq :  std_logic;

  -- Note that none of the ARM processor's direct connections to pads is
  -- defined as I/O on this module. Normally, they should be connected
  -- as toplevel ports here, but that confuses Vivado 2013.4 to think that
  -- some of these ports are real I/Os, causing an implementation failure.
  -- This detachment results in a lot of warnings during synthesis and
  -- implementation, but has no practical significance, as these pads are
  -- completely unrelated to the FPGA bitstream.

  signal PS_CLK :  std_logic;
  signal PS_PORB :  std_logic;
  signal PS_SRSTB :  std_logic;
  signal DDR_Addr : std_logic_vector(14 DOWNTO 0);
  signal DDR_BankAddr : std_logic_vector(2 DOWNTO 0);
  signal DDR_CAS_n : std_logic;
  signal DDR_CKE : std_logic;
  signal DDR_CS_n : std_logic;
  signal DDR_Clk : std_logic;
  signal DDR_Clk_n : std_logic;
  signal DDR_DM : std_logic_vector(3 DOWNTO 0);
  signal DDR_DQ : std_logic_vector(31 DOWNTO 0);
  signal DDR_DQS : std_logic_vector(3 DOWNTO 0);
  signal DDR_DQS_n : std_logic_vector(3 DOWNTO 0);
  signal DDR_DRSTB : std_logic;
  signal DDR_ODT : std_logic;
  signal DDR_RAS_n : std_logic;
  signal DDR_VRN : std_logic;
  signal DDR_VRP : std_logic;
  signal MIO : std_logic_vector(53 DOWNTO 0);
  signal DDR_WEB : std_logic;
  
begin
  xillybus_ins : xillybus
    port map (
      -- Ports related to /dev/xillybus_command
      -- CPU to FPGA signals:
      user_w_command_wren => user_w_command_wren,
      user_w_command_full => user_w_command_full,
      user_w_command_data => user_w_command_data,
      user_w_command_open => user_w_command_open,

      -- Ports related to /dev/xillybus_config
      -- CPU to FPGA signals:
      user_w_config_wren => user_w_config_wren,
      user_w_config_full => user_w_config_full,
      user_w_config_data => user_w_config_data,
      user_w_config_open => user_w_config_open,
      -- Address signals:
      user_config_addr => user_config_addr,
      user_config_addr_update => user_config_addr_update,

      -- Ports related to /dev/xillybus_read_32
      -- FPGA to CPU signals:
      user_r_read_32_rden => user_r_read_32_rden,
      user_r_read_32_empty => user_r_read_32_empty,
      user_r_read_32_data => user_r_read_32_data,
      user_r_read_32_eof => user_r_read_32_eof,
      user_r_read_32_open => user_r_read_32_open,

      -- Ports related to /dev/xillybus_write_feature_32
      -- CPU to FPGA signals:
      user_w_write_feature_32_wren => user_w_write_feature_32_wren,
      user_w_write_feature_32_full => user_w_write_feature_32_full,
      user_w_write_feature_32_data => user_w_write_feature_32_data,
      user_w_write_feature_32_open => user_w_write_feature_32_open,

      -- Ports related to /dev/xillybus_write_kernel_32
      -- CPU to FPGA signals:
      user_w_write_kernel_32_wren => user_w_write_kernel_32_wren,
      user_w_write_kernel_32_full => user_w_write_kernel_32_full,
      user_w_write_kernel_32_data => user_w_write_kernel_32_data,
      user_w_write_kernel_32_open => user_w_write_kernel_32_open,

      -- Ports related to Xillybus Lite
      user_clk => user_clk,
      user_wren => user_wren,
      user_rden => user_rden,
      user_wstrb => user_wstrb,
      user_addr => user_addr,
      user_rd_data => user_rd_data,
      user_wr_data => user_wr_data,
      user_irq => user_irq,

      -- General signals
      PS_CLK => PS_CLK,
      PS_PORB => PS_PORB,
      PS_SRSTB => PS_SRSTB,
      clk_100 => clk_100,
      otg_oc => otg_oc,
      DDR_Addr => DDR_Addr,
      DDR_BankAddr => DDR_BankAddr,
      DDR_CAS_n => DDR_CAS_n,
      DDR_CKE => DDR_CKE,
      DDR_CS_n => DDR_CS_n,
      DDR_Clk => DDR_Clk,
      DDR_Clk_n => DDR_Clk_n,
      DDR_DM => DDR_DM,
      DDR_DQ => DDR_DQ,
      DDR_DQS => DDR_DQS,
      DDR_DQS_n => DDR_DQS_n,
      DDR_DRSTB => DDR_DRSTB,
      DDR_ODT => DDR_ODT,
      DDR_RAS_n => DDR_RAS_n,
      DDR_VRN => DDR_VRN,
      DDR_VRP => DDR_VRP,
      MIO => MIO,
      PS_GPIO => PS_GPIO,
      DDR_WEB => DDR_WEB,
      GPIO_LED => GPIO_LED,
      bus_clk => bus_clk,
      quiesce => quiesce,
      vga4_blue => vga4_blue,
      vga4_green => vga4_green,
      vga4_red => vga4_red,
      vga_hsync => vga_hsync,
      vga_vsync => vga_vsync
  );

  -- Xillybus Lite
  
  user_irq <= '0'; -- No interrupts for now

  lite_addr <= conv_integer(user_addr(6 DOWNTO 2));

  process (user_clk)
  begin
    if (user_clk'event and user_clk = '1') then
      if (user_wstrb(0) = '1') then 
        litearray0(lite_addr) <= user_wr_data(7 DOWNTO 0);
      end if;

      if (user_wstrb(1) = '1') then 
        litearray1(lite_addr) <= user_wr_data(15 DOWNTO 8);
      end if;

      if (user_wstrb(2) = '1') then 
        litearray2(lite_addr) <= user_wr_data(23 DOWNTO 16);
      end if;

      if (user_wstrb(3) = '1') then 
        litearray3(lite_addr) <= user_wr_data(31 DOWNTO 24);
      end if;

      if (user_rden = '1') then
        user_rd_data <= litearray3(lite_addr) & litearray2(lite_addr) &
                        litearray1(lite_addr) & litearray0(lite_addr);
      end if;
    end if;
  end process;

  -- custom design

  srcnn_inst : custom_design
    port map(
        -- global
        clk => bus_clk,

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
  
end sample_arch;
