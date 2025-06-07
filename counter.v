module Counter(input wire clk,
               input wire rst,
               output reg[31:0] count)

    parameter MAX_COUNT_20MS = 20'd1000_000 - 1;

    always@(posedge clk or negedge rst)
        if (!rst) 
            count <= 32'd0;
        else if (count == MAX_COUNT)
            count <= 32'd0;
        else
            count <= count + 32'd1;
endmodule
