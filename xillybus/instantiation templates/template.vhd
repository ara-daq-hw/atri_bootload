architecture sample_arch of template is
  component xillybus
    port (
      PCIE_250M_N : IN std_logic;
      PCIE_250M_P : IN std_logic;
      PCIE_PERST_B_LS : IN std_logic;
      PCIE_RX0_N : IN std_logic;
      PCIE_RX0_P : IN std_logic;
      GPIO_LED : OUT std_logic_vector(3 DOWNTO 0);
      PCIE_TX0_N : OUT std_logic;
      PCIE_TX0_P : OUT std_logic;
      bus_clk : OUT std_logic;
      quiesce : OUT std_logic;
      user_w_spi_in_wren : OUT std_logic;
      user_w_spi_in_full : IN std_logic;
      user_w_spi_in_data : OUT std_logic_vector(7 DOWNTO 0);
      user_w_spi_in_open : OUT std_logic;
      user_r_spi_out_rden : OUT std_logic;
      user_r_spi_out_empty : IN std_logic;
      user_r_spi_out_data : IN std_logic_vector(7 DOWNTO 0);
      user_r_spi_out_eof : IN std_logic;
      user_r_spi_out_open : OUT std_logic);
  end component;

  signal bus_clk :  std_logic;
  signal quiesce : std_logic;
  signal user_w_spi_in_wren :  std_logic;
  signal user_w_spi_in_full :  std_logic;
  signal user_w_spi_in_data :  std_logic_vector(7 DOWNTO 0);
  signal user_w_spi_in_open :  std_logic;
  signal user_r_spi_out_rden :  std_logic;
  signal user_r_spi_out_empty :  std_logic;
  signal user_r_spi_out_data :  std_logic_vector(7 DOWNTO 0);
  signal user_r_spi_out_eof :  std_logic;
  signal user_r_spi_out_open :  std_logic;

begin
  xillybus_ins : xillybus
    port map (
      -- Ports related to /dev/xillybus_spi_in
      -- CPU to FPGA signals:
      user_w_spi_in_wren => user_w_spi_in_wren,
      user_w_spi_in_full => user_w_spi_in_full,
      user_w_spi_in_data => user_w_spi_in_data,
      user_w_spi_in_open => user_w_spi_in_open,

      -- Ports related to /dev/xillybus_spi_out
      -- FPGA to CPU signals:
      user_r_spi_out_rden => user_r_spi_out_rden,
      user_r_spi_out_empty => user_r_spi_out_empty,
      user_r_spi_out_data => user_r_spi_out_data,
      user_r_spi_out_eof => user_r_spi_out_eof,
      user_r_spi_out_open => user_r_spi_out_open,

      -- General signals
      PCIE_250M_N => PCIE_250M_N,
      PCIE_250M_P => PCIE_250M_P,
      PCIE_PERST_B_LS => PCIE_PERST_B_LS,
      PCIE_RX0_N => PCIE_RX0_N,
      PCIE_RX0_P => PCIE_RX0_P,
      GPIO_LED => GPIO_LED,
      PCIE_TX0_N => PCIE_TX0_N,
      PCIE_TX0_P => PCIE_TX0_P,
      bus_clk => bus_clk,
      quiesce => quiesce
  );
end sample_arch;
