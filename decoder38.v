module Decoder38(input wire[2:0] val,
                output reg[7:0] code)

    case (val)
    3'd0: assign code = 8'b0000_0000;
    3'd1: assign code = 8'b0000_0001;
    3'd2: assign code = 8'b0000_0010;
    3'd3: assign code = 8'b0000_0100;
    3'd4: assign code = 8'b0000_1000;
    3'd5: assign code = 8'b0001_0000;
    3'd6: assign code = 8'b0010_0000;
    3'd7: assign code = 8'b0100_0000;
    default:;
    endcase
endmodule
