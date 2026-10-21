module xillydemo
  (
  input clk_50,

  inout [33:0] J5,  //BANK35 V3V3
  inout [33:0] J6,  //BANK33 VADJ

  output  hdmi_clk_p,
  output  hdmi_clk_n,
  output [2:0] hdmi_d_p,
  output [2:0] hdmi_d_n,

  input  uart_rxd,
  output uart_txd,

  output MDIO_PHY_mdc,
  inout  MDIO_PHY_mdio_io,
  input  [3:0]RGMII_rd,
  input  RGMII_rx_ctl,
  input  RGMII_rxc,
  output [3:0]RGMII_td,
  output RGMII_tx_ctl,
  output RGMII_txc,

  inout EEPROM_SCL, EEPROM_SDA,

  inout LCD_SCL, LCD_SDA, LCD_CS,
  output LCD_DC, LCD_RES, LCD_BLK,

  output LED1, LED2,
  input KEY1, KEY2
  );

   localparam gpio_width = 34;
   wire [3:0]  GPIO_LED;
   wire [63:0] gpio_tri_i, gpio_tri_o, gpio_tri_t;

   assign  LED1 = GPIO_LED[0];
   assign  LED2 = gpio_tri_t[63] ? 0 : gpio_tri_o[63];
   assign  gpio_tri_i[62] = KEY2;
   assign  gpio_tri_i[61] = KEY1;

   wire MDIO_PHY_mdio_i, MDIO_PHY_mdio_o, MDIO_PHY_mdio_t;
   wire eeprom_scl_i, eeprom_scl_o, eeprom_scl_t;
   wire eeprom_sda_i, eeprom_sda_o, eeprom_sda_t;
   wire spi_sck_o, spi_io0_o, spi_ss_o;
   wire spi_sck_i, spi_io0_i, spi_ss_i;
   wire spi_sck_t, spi_io0_t, spi_ss_t;

   IOBUF MDIO_PHY_0_mdio_iobuf
     (.I(MDIO_PHY_mdio_o),
      .IO(MDIO_PHY_mdio_io),
      .O(MDIO_PHY_mdio_i),
      .T(MDIO_PHY_mdio_t));

   IOBUF eeprom_iobuf [1:0]
     (.I({eeprom_scl_o, eeprom_sda_o}),
      .O({eeprom_scl_i, eeprom_sda_i}),
      .T({eeprom_scl_t, eeprom_sda_t}),
      .IO({EEPROM_SCL, EEPROM_SDA}));

   IOBUF gpio_iobuf [gpio_width-1:0]
     (.I(gpio_tri_o[gpio_width-1:0]),
      .O(gpio_tri_i[gpio_width-1:0]),
      .T(gpio_tri_t[gpio_width-1:0]),
      .IO(J5));

   IOBUF lcd_iobuf [2:0]
     (.I({spi_sck_o, spi_io0_o, spi_ss_o}),
      .O({spi_sck_i, spi_io0_i, spi_ss_i}),
      .T({spi_sck_t, spi_io0_t, spi_ss_t}),
      .IO({LCD_SCL, LCD_SDA, LCD_CS}));

   assign LCD_RES = gpio_tri_t[60] ? 0 : gpio_tri_o[60];
   assign LCD_DC = gpio_tri_t[59] ? 0 : gpio_tri_o[59];
   assign LCD_BLK = gpio_tri_t[58] ? 0 : gpio_tri_o[58];


   wire [13:0] adc_pins={J6[30],J6[31],J6[28],J6[29],J6[26],J6[27],J6[24],
                        J6[25],J6[22],J6[23],J6[20],J6[21],J6[18],J6[19]};
     vivado_system vivado_system_i
		 (
	      .GPIO_0_tri_i(gpio_tri_i),
          .GPIO_LED(GPIO_LED),
          .adc_data(adc_pins),.adc_otra(J6[33]),
          .adc_clka(J6[32]),.adc_clkb(J6[17]),
		  .GPIO_0_tri_o(gpio_tri_o),
		  .GPIO_0_tri_t(gpio_tri_t),

		  .dvi_clk_n(hdmi_clk_n),
		  .dvi_clk_p(hdmi_clk_p),
		  .dvi_d_n(hdmi_d_n),
		  .dvi_d_p(hdmi_d_p),








		  .MDIO_PHY_0_mdc(MDIO_PHY_mdc),
		  .MDIO_PHY_0_mdio_i(MDIO_PHY_mdio_i),
		  .MDIO_PHY_0_mdio_o(MDIO_PHY_mdio_o),
		  .MDIO_PHY_0_mdio_t(MDIO_PHY_mdio_t),
		  .RGMII_0_rd(RGMII_rd),
		  .RGMII_0_rx_ctl(RGMII_rx_ctl),
		  .RGMII_0_rxc(RGMII_rxc),
		  .RGMII_0_td(RGMII_td),
		  .RGMII_0_tx_ctl(RGMII_tx_ctl),
		  .RGMII_0_txc(RGMII_txc),

		  .SPI_0_0_io0_i(spi_io0_i),
		  .SPI_0_0_io0_o(spi_io0_o),
		  .SPI_0_0_io0_t(spi_io0_t),
		  .SPI_0_0_io1_i(1'b0),
		  .SPI_0_0_io1_o(),
		  .SPI_0_0_io1_t(),
		  .SPI_0_0_sck_i(spi_sck_i),
		  .SPI_0_0_sck_o(spi_sck_o),
		  .SPI_0_0_sck_t(spi_sck_t),
		  .SPI_0_0_ss1_o(),
		  .SPI_0_0_ss2_o(),
		  .SPI_0_0_ss_i(1'b0),
		  .SPI_0_0_ss_o(spi_ss_o),
		  .SPI_0_0_ss_t(spi_ss_t),

		  .IIC_0_0_scl_i(eeprom_scl_i),
		  .IIC_0_0_scl_o(eeprom_scl_o),
		  .IIC_0_0_scl_t(eeprom_scl_t),
		  .IIC_0_0_sda_i(eeprom_sda_i),
		  .IIC_0_0_sda_o(eeprom_sda_o),
		  .IIC_0_0_sda_t(eeprom_sda_t),

		  .IIC_1_0_scl_i(1'b0),
		  .IIC_1_0_scl_o(),
		  .IIC_1_0_scl_t(),
		  .IIC_1_0_sda_i(1'b0),
		  .IIC_1_0_sda_o(),
		  .IIC_1_0_sda_t(),

















































		  .UART_0_0_rxd(uart_rxd),
		  .UART_0_0_txd(uart_txd)
		  );
endmodule
