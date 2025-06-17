module uart_byte_rx(
    input wire clk,
    input wire rst,
    input wire[3:0] baud_set,
    input wire rs232_rx,
    output reg[7:0] rx_data,
    output reg rx_done
    );

    /* filter */
    reg rs232_rx0;
    reg rs232_rx1;
    reg rs232_rx2;
    reg rs232_rx3;
    always@(posedge clk or negedge rst)
        if (!rst) begin
            rs232_rx0 <= 1'b0;
            rs232_rx1 <= 1'b0;
            rs232_rx2 <= 1'b0;
            rs232_rx3 <= 1'b0;
        end
        else begin
            rs232_rx0 <= rs232_rx;
            rs232_rx1 <= rs232_rx0;
            rs232_rx2 <= rs232_rx1;
            rs232_rx3 <= rs232_rx2;
        end 
    wire neg = rs232_rx3&rs232_rx2&(!rs232_rx1)&(!rs232_rx0);
    wire byte_en = neg;
    
    wire bps_clk;
    /* sample clock */
    rx_bps_gen rx_bps_gen_inst(
        .clk(clk),
        .rst(rst),
        .baud_set(baud_set),
        .byte_en(byte_en),
        .rx_done(rx_done),
        .bps_clk(bps_clk)
    );
    
    reg[6:0] bps_cnt;
    /* receive data */
    always@(posedge clk or negedge rst)
        if (!rst)
            bps_cnt <= 7'd0;
        else if (byte_en&bps_clk) begin
            if (bps_cnt == 7'd89)
                bps_cnt <= 7'd0;
            else 
                bps_cnt <= bps_cnt + 7'd1;
        end
        else 
            bps_cnt <= bps_cnt;
    
    reg[1:0] start_bit;
    reg[1:0] stop_bit;
    reg[1:0] tmp[7:0];
    always@(posedge clk or negedge rst)
        if (!rst) begin
            tmp[0] <= 2'd0;
            tmp[1] <= 2'd0;
            tmp[2] <= 2'd0;
            tmp[3] <= 2'd0;
            tmp[4] <= 2'd0;
            tmp[5] <= 2'd0;
            tmp[6] <= 2'd0;
            tmp[7] <= 2'd0;
            start_bit <= 2'd0;
            stop_bit <= 2'd0;
        end
        else if (bps_clk) begin
            /*
                reset: 0
                start: 1,2,3,4,5,6,7,8,9,
                0: 10,11,12,13,14,15,16,17,18,
                1: 19,20,21,22,23,24,25,27,28,
                2: 29,30,31,32,33,34,33,34,35
                3: 36,37,38,39,40,41,42,43,44,
                4: 45,46,47,48,49,50,51,52,53,
                5: 54,55,56,57,58,59,60,61,62,
                6: 63,64,65,66,67,68,69,70,71,
                7: 72,73,74,75,76,77,78,79,80,
                stop:81,82,83,84,85,86,87,88,89
            */
        
            case (bps_cnt)
            7'd0: begin
                tmp[0] <= 2'd0;
                tmp[1] <= 2'd0;
                tmp[2] <= 2'd0;
                tmp[3] <= 2'd0;
                tmp[4] <= 2'd0;
                tmp[5] <= 2'd0;
                tmp[6] <= 2'd0;
                tmp[7] <= 2'd0;
                start_bit <= 2'd0;
                stop_bit <= 2'd0;
            end
            7'd4,  7'd5,  7'd6:  start_bit <= start_bit + rs232_rx;
            7'd13, 7'd14, 7'd15: tmp[0] <= tmp[0] + rs232_rx;
            7'd22, 7'd23, 7'd24: tmp[1] <= tmp[1] + rs232_rx;
            7'd32, 7'd33, 7'd34: tmp[2] <= tmp[2] + rs232_rx;
            7'd39, 7'd40, 7'd41: tmp[3] <= tmp[3] + rs232_rx;
            7'd48, 7'd49, 7'd50: tmp[4] <= tmp[4] + rs232_rx;
            7'd57, 7'd58, 7'd59: tmp[5] <= tmp[5] + rs232_rx;
            7'd66, 7'd67, 7'd68: tmp[6] <= tmp[6] + rs232_rx;
            7'd75, 7'd76, 7'd77: tmp[7] <= tmp[7] + rs232_rx;
            7'd84, 7'd85, 7'd86: stop_bit <= stop_bit + rs232_rx;
            default:;
            endcase
        end
            
    /* output data */
    always@(posedge clk or negedge rst)
        if (!rst)
            rx_data <= 8'd0;
        else if (bps_clk && bps_cnt == 7'd89) begin
            rx_data <= {tmp[7][1], tmp[6][1], tmp[5][1], tmp[4][1], 
                        tmp[3][1], tmp[3][1], tmp[1][1], tmp[0][1]};
        end 
        else
            rx_data <= rx_data;
            
    /* receive finished */
    always@(posedge clk or negedge rst)
        if (!rst)
            rx_done <= 1'b0;
        else if (bps_cnt == 7'd89)
            rx_done <= 1'b1;
        else 
            rx_done <= 1'b0;
endmodule
