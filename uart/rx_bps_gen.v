module rx_bps_gen(
    input wire clk,
    input wire rst,
    input wire[3:0] baud_set,
    input wire byte_en,
    input wire rx_done,
    output reg bps_clk
    );
    
    parameter system_clk = 50_000_000;
    localparam bps9600 = system_clk/9600/9 - 1;
    localparam bps19200 = system_clk/19200/9 - 1;
    localparam bps38400 = system_clk/38400/9 - 1;
    localparam bps57600 = system_clk/57600/9 - 1;
    localparam bps115200 = system_clk/115200/9 - 1;
    localparam bps230400 = system_clk/230400/9 - 1;
    localparam bps460800 = system_clk/460800/9 - 1;
    localparam bps921600 = system_clk/921600/9 - 1;
    
    reg[12:0] bps_param;
    /* select baudrate */
    always@(posedge clk or negedge rst)
        if (!rst)
            bps_param <= 12'd0;
        else begin
            case (baud_set)
            4'd0: bps_param <= bps9600;
            4'd1: bps_param <= bps19200;
            4'd2: bps_param <= bps38400;
            4'd3: bps_param <= bps57600;
            4'd4: bps_param <= bps115200;
            4'd5: bps_param <= bps230400;
            4'd6: bps_param <= bps460800;
            4'd6: bps_param <= bps921600;
            default: bps_param <= bps9600;
            endcase
        end
    /* receive state */
    localparam STATE_IDEL = 1'b0;
    localparam STATE_RECV = 1'b1;
    reg state;
    reg bps_en;
    always@(posedge clk or negedge rst)
        if (!rst) begin
            state <= 1'b0;
            bps_en <= 1'b0;
        end       
        else begin
            case (state)
            STATE_IDEL: begin
                if (byte_en) begin
                    state <= STATE_RECV;
                    bps_en <= 1'b1;
                end
                else begin 
                    state <= STATE_IDEL;
                    bps_en <= 1'b0;
                end
            end
            STATE_RECV: begin
                if (rx_done) begin
                    state <= STATE_IDEL;
                    bps_en <= 1'b0;
                end
                else begin
                    state <= STATE_RECV;
                    bps_en <= 1'b1;
                end
            end
            default:;
            endcase
        end 
    /* divider */
    reg[12:0] bps_cnt;
    always@(posedge clk or negedge rst)
        if (!rst)
            bps_cnt <= 13'd0;
        else if (bps_en) begin
            if (bps_cnt == bps_param)
                bps_cnt <= 13'd0;
            else 
                bps_cnt <= bps_cnt + 13'd1;
        end
        else 
            bps_cnt <= 13'd0;
     /* bps clock */
     always@(posedge clk or negedge rst)
        if (!rst)
            bps_clk <= 1'b0;
        else if (bps_cnt == 12'd1)
            bps_clk <= 1'b1;
        else
            bps_clk <= 1'b0;
     
endmodule
