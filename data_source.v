module data_source (
    input wire clk,
    input wire rst_n,
    output reg fifo_write_valid,
    output reg [8:0] fifo_write_data,
    input wire fifo_write_ready,
    output reg lcd_resetn
);

localparam MAX_CMDS = 69;
reg [8:0] init_cmd[MAX_CMDS:0];

localparam INIT_RESET   = 4'd0;
localparam INIT_PREPARE = 4'd1;
localparam INIT_WAKEUP  = 4'd2;
localparam INIT_SNOOZE  = 4'd3;
localparam INIT_WORKING = 4'd4;
localparam SEND_PIXEL_H = 4'd5;
localparam SEND_PIXEL_L = 4'd6;
localparam FRAME_DONE   = 4'd7;

localparam CNT_100MS = 32'd2700000;
localparam CNT_120MS = 32'd3240000;
localparam CNT_200MS = 32'd5400000;

reg [3:0] init_state;
reg [6:0] cmd_index;
reg [31:0] delay_cnt;
reg [15:0] pixel_cnt;
reg [15:0] pixel_data;
reg [3:0] frame_cmd_index;

localparam LCD_WIDTH = 240;
localparam LCD_HEIGHT = 135;
localparam PIXEL_COUNT = LCD_WIDTH * LCD_HEIGHT;

localparam COLOR_BLUE  = 16'h001F;
localparam COLOR_GREEN = 16'h07E0;
localparam COLOR_RED   = 16'hF800;

localparam CMD_CASET = 9'h02A;
localparam CMD_RASET = 9'h02B;
localparam CMD_RAMWR = 9'h02C;

initial begin
    init_cmd[0] = 9'h036;
    init_cmd[1] = 9'h170;
    init_cmd[2] = 9'h03A;
    init_cmd[3] = 9'h105;
    init_cmd[4] = 9'h0B2;
    init_cmd[5] = 9'h10C;
    init_cmd[6] = 9'h10C;
    init_cmd[7] = 9'h100;
    init_cmd[8] = 9'h133;
    init_cmd[9] = 9'h133;
    init_cmd[10] = 9'h0B7;
    init_cmd[11] = 9'h135;
    init_cmd[12] = 9'h0BB;
    init_cmd[13] = 9'h119;
    init_cmd[14] = 9'h0C0;
    init_cmd[15] = 9'h12C;
    init_cmd[16] = 9'h0C2;
    init_cmd[17] = 9'h101;
    init_cmd[18] = 9'h0C3;
    init_cmd[19] = 9'h112;
    init_cmd[20] = 9'h0C4;
    init_cmd[21] = 9'h120;
    init_cmd[22] = 9'h0C6;
    init_cmd[23] = 9'h10F;
    init_cmd[24] = 9'h0D0;
    init_cmd[25] = 9'h1A4;
    init_cmd[26] = 9'h1A1;
    init_cmd[27] = 9'h0E0;
    init_cmd[28] = 9'h1D0;
    init_cmd[29] = 9'h104;
    init_cmd[30] = 9'h10D;
    init_cmd[31] = 9'h111;
    init_cmd[32] = 9'h113;
    init_cmd[33] = 9'h12B;
    init_cmd[34] = 9'h13F;
    init_cmd[35] = 9'h154;
    init_cmd[36] = 9'h14C;
    init_cmd[37] = 9'h118;
    init_cmd[38] = 9'h10D;
    init_cmd[39] = 9'h10B;
    init_cmd[40] = 9'h11F;
    init_cmd[41] = 9'h123;
    init_cmd[42] = 9'h0E1;
    init_cmd[43] = 9'h1D0;
    init_cmd[44] = 9'h104;
    init_cmd[45] = 9'h10C;
    init_cmd[46] = 9'h111;
    init_cmd[47] = 9'h113;
    init_cmd[48] = 9'h12C;
    init_cmd[49] = 9'h13F;
    init_cmd[50] = 9'h144;
    init_cmd[51] = 9'h151;
    init_cmd[52] = 9'h12F;
    init_cmd[53] = 9'h11F;
    init_cmd[54] = 9'h11F;
    init_cmd[55] = 9'h120;
    init_cmd[56] = 9'h123;
    init_cmd[57] = 9'h021;
    init_cmd[58] = 9'h029;
    init_cmd[59] = 9'h02A;
    init_cmd[60] = 9'h100;
    init_cmd[61] = 9'h128;
    init_cmd[62] = 9'h101;
    init_cmd[63] = 9'h117;
    init_cmd[64] = 9'h02B;
    init_cmd[65] = 9'h100;
    init_cmd[66] = 9'h135;
    init_cmd[67] = 9'h100;
    init_cmd[68] = 9'h1BB;
    init_cmd[69] = 9'h02C;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        init_state <= INIT_RESET;
        cmd_index <= 0;
        delay_cnt <= 0;
        pixel_cnt <= 0;
        frame_cmd_index <= 0;
        lcd_resetn <= 0;
        fifo_write_valid <= 0;
        fifo_write_data <= 0;
    end else begin
        fifo_write_valid <= 0;
        case (init_state)
            INIT_RESET: begin
                lcd_resetn <= 0;
                if (delay_cnt == CNT_100MS) begin
                    delay_cnt <= 0;
                    init_state <= INIT_PREPARE;
                    lcd_resetn <= 1;
                end else begin
                    delay_cnt <= delay_cnt + 1;
                end
            end
            INIT_PREPARE: begin
                if (delay_cnt == CNT_200MS) begin
                    delay_cnt <= 0;
                    init_state <= INIT_WAKEUP;
                end else begin
                    delay_cnt <= delay_cnt + 1;
                end
            end
            INIT_WAKEUP: begin
                if (fifo_write_ready && !fifo_write_valid) begin
                    fifo_write_valid <= 1;
                    fifo_write_data <= 9'h011;
                    init_state <= INIT_SNOOZE;
                end
            end
            INIT_SNOOZE: begin
                if (delay_cnt == CNT_120MS) begin
                    delay_cnt <= 0;
                    cmd_index <= 0;
                    init_state <= INIT_WORKING;
                end else begin
                    delay_cnt <= delay_cnt + 1;
                end
            end
            INIT_WORKING: begin
                if (cmd_index <= MAX_CMDS) begin
                    if (fifo_write_ready && !fifo_write_valid) begin
                        fifo_write_valid <= 1;
                        fifo_write_data <= init_cmd[cmd_index];
                        cmd_index <= cmd_index + 1;
                    end
                end else begin
                    init_state <= SEND_PIXEL_H;
                    pixel_cnt <= 0;
                end
            end
            SEND_PIXEL_H: begin
                if (pixel_cnt < PIXEL_COUNT) begin
                    if (pixel_cnt < (PIXEL_COUNT / 3))
                        pixel_data <= COLOR_BLUE;
                    else if (pixel_cnt < (PIXEL_COUNT * 2 / 3))
                        pixel_data <= COLOR_GREEN;
                    else
                        pixel_data <= COLOR_RED;
                    if (fifo_write_ready && !fifo_write_valid) begin
                        fifo_write_valid <= 1;
                        fifo_write_data <= {1'b1, pixel_data[15:8]};
                        init_state <= SEND_PIXEL_L;
                    end
                end else begin
                    init_state <= FRAME_DONE;
                    frame_cmd_index <= 0;
                end
            end
            SEND_PIXEL_L: begin
                if (fifo_write_ready && !fifo_write_valid) begin
                    fifo_write_valid <= 1;
                    fifo_write_data <= {1'b1, pixel_data[7:0]};
                    pixel_cnt <= pixel_cnt + 1;
                    init_state <= SEND_PIXEL_H;
                end
            end
            FRAME_DONE: begin
                if (fifo_write_ready && !fifo_write_valid) begin
                    fifo_write_valid <= 1;
                    case (frame_cmd_index)
                        4'd0: fifo_write_data <= CMD_CASET;
                        4'd1: fifo_write_data <= 9'h100;
                        4'd2: fifo_write_data <= 9'h128;
                        4'd3: fifo_write_data <= 9'h101;
                        4'd4: fifo_write_data <= 9'h117;
                        4'd5: fifo_write_data <= CMD_RASET;
                        4'd6: fifo_write_data <= 9'h100;
                        4'd7: fifo_write_data <= 9'h135;
                        4'd8: fifo_write_data <= 9'h100;
                        4'd9: fifo_write_data <= 9'h1BB;
                        4'd10: fifo_write_data <= CMD_RAMWR;
                    endcase
                    if (frame_cmd_index == 4'd10) begin
                        frame_cmd_index <= 0;
                        pixel_cnt <= 0;
                        init_state <= SEND_PIXEL_H;
                    end else begin
                        frame_cmd_index <= frame_cmd_index + 1;
                    end
                end
            end
            default: init_state <= INIT_RESET;
        endcase
    end
end

endmodule
