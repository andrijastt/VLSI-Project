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

    reg [7:0] data_reg, data_next;
    wire [3:0] display_reg0;
    wire [3:0] display_reg1;

    assign display_reg0 = data_reg[3:0];
    assign display_reg1 = data_reg[7:4];

    hex hex_inst0(.in(display_reg0), .out(out0));
    hex hex_inst1(.in(display_reg1), .out(out1));

    reg [3:0] i = 4'h0;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_reg <= 8'h00;
        end
        else begin
            data_reg <= data_next;
        end
    end

    always @(*) begin
        data_next = data_reg;

        if(deb_kbclk) begin
            
            // bits that are data
            if(i > 4'h0 || i < 4'h09) begin
                data_next[i - 1] = in;
            end

            i = i + 4'h01;

            if(i == 4'hB) begin
                i = 4'h0;
            end
        end
        else begin
            i = 4'h00;
        end

    end


endmodule
