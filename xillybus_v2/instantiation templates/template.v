  // Clock and quiesce
  wire  bus_clk;
  wire  quiesce;


  // Wires related to /dev/xillybus_icap_in
  wire  user_w_icap_in_wren;
  wire  user_w_icap_in_full;
  wire [15:0] user_w_icap_in_data;
  wire  user_w_icap_in_open;

  // Wires related to /dev/xillybus_spi_in
  wire  user_w_spi_in_wren;
  wire  user_w_spi_in_full;
  wire [7:0] user_w_spi_in_data;
  wire  user_w_spi_in_open;

  // Wires related to /dev/xillybus_spi_out
  wire  user_r_spi_out_rden;
  wire  user_r_spi_out_empty;
  wire [7:0] user_r_spi_out_data;
  wire  user_r_spi_out_eof;
  wire  user_r_spi_out_open;


  xillybus xillybus_ins (

    // Ports related to /dev/xillybus_icap_in
    // CPU to FPGA signals:
    .user_w_icap_in_wren(user_w_icap_in_wren),
    .user_w_icap_in_full(user_w_icap_in_full),
    .user_w_icap_in_data(user_w_icap_in_data),
    .user_w_icap_in_open(user_w_icap_in_open),


    // Ports related to /dev/xillybus_spi_in
    // CPU to FPGA signals:
    .user_w_spi_in_wren(user_w_spi_in_wren),
    .user_w_spi_in_full(user_w_spi_in_full),
    .user_w_spi_in_data(user_w_spi_in_data),
    .user_w_spi_in_open(user_w_spi_in_open),


    // Ports related to /dev/xillybus_spi_out
    // FPGA to CPU signals:
    .user_r_spi_out_rden(user_r_spi_out_rden),
    .user_r_spi_out_empty(user_r_spi_out_empty),
    .user_r_spi_out_data(user_r_spi_out_data),
    .user_r_spi_out_eof(user_r_spi_out_eof),
    .user_r_spi_out_open(user_r_spi_out_open),


    // General signals
    .PCIE_250M_N(PCIE_250M_N),
    .PCIE_250M_P(PCIE_250M_P),
    .PCIE_PERST_B_LS(PCIE_PERST_B_LS),
    .PCIE_RX0_N(PCIE_RX0_N),
    .PCIE_RX0_P(PCIE_RX0_P),
    .GPIO_LED(GPIO_LED),
    .PCIE_TX0_N(PCIE_TX0_N),
    .PCIE_TX0_P(PCIE_TX0_P),
    .bus_clk(bus_clk),
    .quiesce(quiesce)
  );
