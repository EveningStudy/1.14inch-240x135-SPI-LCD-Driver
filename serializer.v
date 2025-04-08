module serializer(
    input clk,
    input rst_n,
    input fifo_valid,         
    input [8:0] fifo_data,   
    output fifo_read_ready,   
    output reg CS,          
    output reg SCLK,       
    output reg D_C,          
    output reg SDA          
);


    localparam IDLE  = 2'd0;
    localparam LOAD  = 2'd1;
    localparam SHIFT = 2'd2;
    localparam DONE  = 2'd3;
    
    reg [1:0] state;
    reg [7:0] shift_reg;  
    reg [2:0] crt;   


    assign fifo_read_ready = (state == IDLE);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            shift_reg <= 8'd0;
            crt   <= 0;
            CS        <= 1;  
            SCLK      <= 0;
            D_C       <= 0;
            SDA       <= 0;
        end else begin
            case (state)
                IDLE: begin
                    CS   <= 1;
                    SCLK <= 0;
                    if (fifo_valid) begin
                        state <= LOAD;
                    end
                end
                LOAD: begin
                    D_C       <= fifo_data[8];  
                    shift_reg <= fifo_data[7:0];
                    crt <= 3'd7;  
                    CS        <= 0;  
                    state     <= SHIFT;
                end
                SHIFT: begin                 
                    if (SCLK == 0) begin
                        SCLK <= 1;
                        SDA  <= shift_reg[crt];
                    end else begin
                        SCLK <= 0;
                        if (crt == 0)
                            state <= DONE;
                        else
                            crt <= crt - 1;
                    end
                end
                DONE: begin
                    CS    <= 1; 
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
