`timescale 1ns / 1ps

module spi_master(
    input wire clk,
    input wire rst,
    input wire tx_req,
    input wire[7:0] tx_data,
    output reg spi_cs,
    output wire spi_clk,
    output wire spi_busy,
    output wire spi_mosi
    );
    
    /* parameter */
    parameter SYS_CLK_FREQ = 26'd50_000_000;
    parameter SPI_CLK_FREQ = 19'd50_0000;
    parameter CPOL = 1'b0;
    parameter CPHA = 1'b0;
    
    localparam[9:0] spi_clk_cnt_max = SYS_CLK_FREQ/SPI_CLK_FREQ;
    localparam[9:0] spi_clk_cnt_max_div2 = spi_clk_cnt_max/2;
    /* internal */
    reg[9:0] clk_div_cnt;
    reg spi_en;
    reg[7:0] tx_data_tmp;
    reg clk1_en;
    reg clk2_en;
    reg spi_clk_tmp;
    reg[3:0] tx_cnt;
    reg spi_strobe_en;
    wire strobe;
    
    assign spi_clk = (CPOL == 1'b1) ? ~spi_clk_tmp : spi_clk_tmp;
    assign spi_mosi = tx_data_tmp[7];
    assign strobe = (CPHA == 1'b1) ? clk1_en&spi_strobe_en : clk2_en&spi_strobe_en;
    assign spi_busy = spi_en;
    
    /* cache data */
    always@(posedge clk or negedge rst)
        if (!rst || (clk1_en && tx_cnt == 4'd8)) begin
            spi_en <= 1'b0;
            tx_data_tmp <= 8'd0;
        end 
        else if ((tx_req == 1'b1)&&(spi_en == 1'b0)) begin
            spi_en <= 1'b1;
            tx_data_tmp <= tx_data;
        end
        else if (spi_en == 1'b1)
            tx_data_tmp <= {tx_data_tmp[6:0],1'b0};
        else 
            tx_data_tmp <= tx_data_tmp; 
            
            
     /* cs */
     always@(posedge clk or negedge rst) 
        if (!rst) 
            spi_cs <= 1'b1;
        else if (spi_en) 
            spi_cs <= 1'b0;
        else 
            spi_cs <= 1'b1;
    
    /* counter */
    always@(posedge clk or negedge rst)
        if (!rst || spi_cs) begin
            clk_div_cnt <= 9'd0;
            clk1_en <= 1'b0;
            clk2_en <= 1'b0;
        end
        else if (clk_div_cnt == spi_clk_cnt_max - 1) begin
            clk2_en <= 1'b1;
            clk_div_cnt <= 9'd0;
        end
        else if (clk_div_cnt == spi_clk_cnt_max_div2 - 1) begin
            clk1_en <= 1'b1;
            clk_div_cnt <= clk_div_cnt + 9'd1;
        end
        else begin
            clk_div_cnt <= clk_div_cnt + 9'd1;
            clk1_en <= 1'b0;
            clk2_en <= 1'b0;
        end
    /* tx counter */
    always@(posedge clk or negedge rst)
        if (!rst || !spi_en)
            tx_cnt <= 4'd0;
        else if (clk1_en)
            tx_cnt <= tx_cnt + 4'd1;
        else 
            tx_cnt <= tx_cnt;
            
    always@(posedge clk or negedge rst)
        if (!rst) 
            spi_strobe_en <= 1'b0;
        else if (tx_cnt < 4'd8)
            if (clk1_en) 
                spi_strobe_en <= 1'b1;
            else 
                spi_strobe_en <= spi_strobe_en;
        else 
            spi_strobe_en <= 1'b0;
            
     always@(posedge clk or negedge rst)
        if (!rst)
            spi_clk_tmp <= 1'b0;
        else if (clk2_en)
            spi_clk_tmp <= 1'b0;
        else if (clk1_en && (tx_cnt < 4'd8))
            spi_clk_tmp <= 1'b1;
        else
            spi_clk_tmp <= spi_clk_tmp;
                     
endmodule
