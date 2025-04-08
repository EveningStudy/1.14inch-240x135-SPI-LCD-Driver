module fifo #(
    parameter DEPTH = 16,
    parameter WIDTH = 9
) (
    input wire clk,
    input wire rst_n,

    input wire read_ready,
    output wire read_valid,
    output reg [WIDTH-1:0] read_data,

    output wire write_ready,
    input wire write_valid,
    input wire [WIDTH-1:0] write_data
);

localparam PTR_BITS = $clog2(DEPTH);
reg [WIDTH-1:0] data [DEPTH-1:0];
reg [PTR_BITS:0] wr_ptr, rd_ptr;
wire [PTR_BITS:0] n = wr_ptr - rd_ptr;

integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            data[i] <= 0;
        end
        wr_ptr <= 0;
        rd_ptr <= 0;
    end else begin
        if (write_valid && write_ready) begin
            data[wr_ptr[PTR_BITS-1:0]] <= write_data;
            wr_ptr <= wr_ptr + 1;
        end
        if (read_valid && read_ready) begin
            read_data <= data[rd_ptr[PTR_BITS-1:0]];
            rd_ptr <= rd_ptr + 1;
        end
    end
end

assign read_valid = (n != 0);
assign write_ready = (n != DEPTH);

endmodule
