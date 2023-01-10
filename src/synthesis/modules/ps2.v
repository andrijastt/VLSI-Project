module ps2(
    input clk,
    input kbclk,
    input rst_n,
    input in,
    output [6:0] out0,
    output [6:0] out1
);

    wire deb_kbclk;
    deb deb_inst(.clk(clk), .rst_n(rst_n), .in(kbclk), .out(deb_kbclk));

    // value used for dsiplay
    reg [7:0] data_reg, data_next;

    // value used for changing value
    reg [7:0] next_reg, next_next;

    wire [3:0] display_reg0;
    wire [3:0] display_reg1;

    assign display_reg0 = data_reg[3:0];
    assign display_reg1 = data_reg[7:4];

    hex hex_inst0(.in(display_reg0), .out(out0));
    hex hex_inst1(.in(display_reg1), .out(out1));

    reg [3:0] i;

    reg state_reg, state_next

    localparam start = 1'b0;
    localparam data_transfer = 1'b1;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_reg <= 8'h00;
            next_reg <= 8'h00;
            i <= 4'h0;
            state_reg <= start;
        end
        else begin
            data_reg <= data_next;
            next_reg <= next_next;
            state_reg <= state_next;
        end
    end

    always @(*) begin
        data_next = data_reg;
        next_next = next_reg;
        state_next = state_reg;

        if(deb_kbclk) begin

            case (state_reg)
                start: begin
                    if(i == 4'h0 && in == 1'b0) begin
                        state_next = data_transfer;
                    end      
                end

                data_transfer: begin

                    if(i < 4'h8) begin
                        next_next[i] = in;
                    end

                    i = i + 4'h1;

                    // reset
                    if (i == 4'h8 && next_next != 8'hF0) begin
                        data_next = next_next;    
                        i = 4'h0;
                    end

                    if(i == 4'hA) begin
                        state_next = start;
                        data_next = 8'h00;      // ne znam da li ovako da stavimo ili ne
                        i = 4'h0;
                    end
                end
            endcase
        end

    end

endmodule
