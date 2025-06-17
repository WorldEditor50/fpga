module spi_slave(
    input wire clk,
    input wire rst,
    input wire spi_cs,
    input wire spi_clk,
    input wire spi_mosi,
    output reg rx_data_valid,
    output reg[BIT_LEN-1:0] rx_data
);
    parameter BIT_LEN = 8;
    parameter CPOL = 1'b0;
    parameter CPHA = 1'b1;
    
    reg[3:0] spi_cs_tmp;
    reg[3:0] spi_clk_tmp;
    reg[3:0] spi_mosi_tmp;
    reg sample;
    reg spi_clk_pos;
    reg spi_clk_neg;
    wire rx_en;
    reg[4:0] rx_bit_cnt;
    
    assign rx_en = ~spi_cs_tmp[3];
    
    always@(posedge clk or negedge rst)
        if (!rst)
            spi_cs_tmp <= 4'd0;
        else 
            spi_cs_tmp <= {spi_cs_tmp[2:0], spi_cs};
            
    always@(posedge clk or negedge rst)
        if (!rst)
            spi_clk_tmp <= 4'd0;
        else 
            spi_clk_tmp <= {spi_clk_tmp[2:0], spi_clk};
    
    always@(posedge clk or negedge rst)
        if (!rst)
            spi_mosi_tmp <= 4'd0;
        else 
            spi_mosi_tmp <= {spi_mosi_tmp[2:0], spi_mosi};    

    /* spi posedge */
    always@(posedge clk or negedge rst) 
        if (!rst)
            spi_clk_pos <= 1'b0;
        else if (spi_clk_tmp[2] == 1'b0 && spi_clk_tmp[1] == 1'b1)
            spi_clk_pos <= 1'b1;
        else
            spi_clk_pos <= 1'b0;
    
    /* spi negedge */
    always@(posedge clk or negedge rst)
        if (!rst)
            spi_clk_neg <= 1'b0;
        else if (spi_clk_tmp[2] == 1'b1 && spi_clk_tmp[1] == 1'b0)
            spi_clk_neg <= 1'b1;
        else
            spi_clk_neg <= 1'b0;
    
    /* sample */
    always@(posedge clk or negedge rst)
        if (!rst)
            sample <= 1'b0;
        else if (CPOL == 1'b0 && CPHA == 1'b0)
            sample <= spi_clk_pos;
        else if (CPOL == 1'b0 && CPHA == 1'b1)
            sample <= spi_clk_neg;
        else if (CPOL == 1'b1 && CPHA == 1'b0)
            sample <= spi_clk_neg;
        else if (CPOL == 1'b1 && CPHA == 1'b1)
            sample <= spi_clk_pos;
        else
            sample <= 1'b0;
        
    /* bit counter  */
    always@(posedge clk or negedge rst)
        if (!rst) begin
            rx_bit_cnt <= 5'd0;
            rx_data_valid <= 1'b0;
        end
        else if (rx_en && sample && rx_bit_cnt < BIT_LEN) begin
            rx_bit_cnt <= rx_bit_cnt + 5'd1;
            rx_data_valid <= 1'b0;
        end
        else if (!rx_en && rx_bit_cnt == BIT_LEN) begin
            rx_bit_cnt <= 5'd0;
            rx_data_valid <= 1'b1;
        end
        else 
            rx_data_valid <= 1'b0;
    
    /* recv data */
    always@(posedge clk or negedge rst) 
        if (!rst)
            rx_data <= 'd0;
        else if (rx_en && sample) 
            rx_data <= {rx_data[BIT_LEN - 2:0], spi_mosi_tmp[3]};
        else if (!rx_en)
            rx_data <= 'd0;
        else
            rx_data <= rx_data;
    
endmodule
