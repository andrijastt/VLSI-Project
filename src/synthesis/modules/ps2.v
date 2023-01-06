module ps2(
    input clk,
    input kbclk,
    input rst_n,
    input in,
    output [6:0] out
);

    wire deb_kbclk;
    deb deb_inst(.clk(clk), .rst_n(rst_n), .in(kbclk), .out(deb_kbclk));

    reg [7:0] data_reg, data_next;
    reg [3:0] display_reg, display_next;

    hex hex_inst(.in(display_reg), .out(out))

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            display_reg <= 4'h0;
            data_reg <= 8'h00;
        end
        else begin
            display_reg <= display_next;
            data_reg <= data_next;
        end
    end

    always(*) begin

        display_next = display_reg;
        data_next = data_reg

        
    end


endmodule
