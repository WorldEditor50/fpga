module KeyFilter(input wire clk,
                 input wire rst,
                 input wire key,
                 output reg keyPress,
                 output reg keyRelease,
                 output reg keyClk)
    parameter MAX_COUNT_20MS = 20'd1000_000 - 1;
    reg key0;
    reg key1;
    reg key2;
    wire pos;
    wire neg;
    reg[29:0] count;
    wire elapseTime20MS;
    
    always@(posedge clk or negedge rst)
        if (!rst) begin
            key0 <= 0;
            key1 <= 0;
            key2 <= 0;
        end
        else begin
            key0 <= key;
            key1 <= key0;
            key2 <= key1;
        end
    assign pos = (key1 == 1)&&(key2 == 0);
    assign neg = (key1 == 0)&&(key2 == 1);

    localparam STATE_IDEL         = 3'b000;
    localparam STATE_PRESS        = 3'b001;
    localparam STATE_WAIT_RELEASE = 3'b010;
    localparam STATE_RELEASE      = 3'b100;
    reg[2:0] state;

    always@(posedge clk or negedge rst)
        if (!rst) begin
            state <= STATE_IDEL;
            keyRelease <= 1'd0;
            keyPress <= 1'd0;
            count <= 30'd0;
            keyClk <= 1'd0;
        end
        else begin
            case (state)
            STATE_IDEL: begin
                keyRelease <= 1'd0;
                if (neg)
                    state <= STATE_PRESS;
                else
                    state <= STATE_IDEL;
            end
            STATE_PRESS: begin
                if (elapseTime20MS) begin
                    state <= STATE_WAIT_RELEASE;
                    keyPress <= 1'd1;
                    keyClk <= 1'd0;
                    count <= 30'd0;
                else if (pos) begin
                    state <= STATE_IDEL;
                    count <= 30'd0;
                end
                else begin
                    count <= count + 1'd1;
                    state <= state;
                end
            end
            STATE_WAIT_RELEASE: begin
                keyPress <= 1'd0;
                if (pos) begin
                    state <= STATE_RELEASE;
                end
                else begin
                    state <= state;
                end
            end
            STATE_RELEASE: begin
                if (elapseTime20MS) begin
                    state <= STATE_IDEL;
                    keyRelease <= 1'd1;
                    keyClk <= 1'd1;
                    count <= 30'd0;
                end
                else if (neg) begin
                    state <= STATE_WAIT_RELEASE;
                    count <= 30'd0;
                end
                else begin
                    count <= count + 1'd1;
                    state <= state;
                end
            end
            default: state <= STATE_IDEL;
            endcase
        end
        assign elapseTime20MS = count >= MAX_COUNT_20MS;

endmodule
