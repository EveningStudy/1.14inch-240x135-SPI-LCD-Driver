module lcd_driver_top (
    input  wire clk,
    input  wire rst_n,
    output wire lcd_resetn,
    output wire lcd_cs,
    output wire lcd_dc,
    output wire lcd_sclk,
    output wire lcd_sda
);

wire ds_fifo_write_valid;
wire [8:0] ds_fifo_write_data;
wire ds_fifo_write_ready;

wire fifo_serial_read_valid;
wire [8:0] fifo_serial_read_data;
wire fifo_serial_read_ready;

data_source data_source_inst (
    .clk(clk),
    .rst_n(rst_n),
    .fifo_write_valid(ds_fifo_write_valid),
    .fifo_write_data(ds_fifo_write_data),
    .fifo_write_ready(ds_fifo_write_ready),
    .lcd_resetn(lcd_resetn)
);

fifo #(
    .DEPTH(16),
    .WIDTH(9)
) fifo_inst (
    .clk(clk),
    .rst_n(rst_n),
    .read_ready(fifo_serial_read_ready),
    .read_valid(fifo_serial_read_valid),
    .read_data(fifo_serial_read_data),
    .write_ready(ds_fifo_write_ready),
    .write_valid(ds_fifo_write_valid),
    .write_data(ds_fifo_write_data)
);

serializer serializer_inst (
    .clk(clk),
    .rst_n(rst_n),
    .fifo_valid(fifo_serial_read_valid),
    .fifo_data(fifo_serial_read_data),
    .fifo_read_ready(fifo_serial_read_ready),
    .CS(lcd_cs),
    .SCLK(lcd_sclk),
    .D_C(lcd_dc),
    .SDA(lcd_sda)
);

endmodule
