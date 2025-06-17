module uart_byte_tx(
    input wire clk,
    input wire rst,
    input wire[3:0] baud_set,
    input wire byte_en,
    input wire[7:0] data_tx,
    output reg tx_done,
    output reg rs232_tx
    );
    
    wire bps_clk;
    reg[3:0] bps_cnt;
    reg[7:0] data;
    /* bps clock */
    tx_bps_gen tx_bps_gen_inst(
        .clk(clk),
        .rst(rst),
        .baud_set(baud_set),
        .byte_en(byte_en),
        .tx_done(tx_done),
        .bps_clk(bps_clk)
        );
            
    /* bps counter */
    always@(posedge clk or negedge rst)
        if (!rst)
            bps_cnt <= 4'd0;
        else if (bps_cnt == 4'd11) 
            bps_cnt <= 4'd0;
        else if (bps_clk) 
            bps_cnt <= bps_cnt + 4'd1;
        else 
            bps_cnt <= bps_cnt;
            
    /* cache data */
    always@(posedge clk or negedge rst)
        if (!rst)
            data <= 8'd0;
        else if (bps_clk & bps_cnt == 4'd1)
            data <= data_tx;
        else
            data <= data;
    /* send data */
    always@(posedge clk or negedge rst)
        if (!rst)
            rs232_tx <= 1'd0;
        else begin
            case (bps_cnt)
            4'd1: rs232_tx <= 0;
            4'd2: rs232_tx <= data[0];
            4'd3: rs232_tx <= data[1];
            4'd4: rs232_tx <= data[2];
            4'd5: rs232_tx <= data[3];
            4'd6: rs232_tx <= data[4];
            4'd7: rs232_tx <= data[5];
            4'd8: rs232_tx <= data[6];
            4'd9: rs232_tx <= data[7];
            4'd10: rs232_tx <= 1;
            default: rs232_tx <= 0;
            endcase
        end
    /* send finished */
    always@(posedge clk or negedge rst)
        if (!rst)
            tx_done <= 1'd0;
        else if (bps_cnt == 4'd11)
            tx_done <= 1'd1;
        else 
            tx_done <= 1'd0;
endmodule
