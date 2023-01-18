module ps2(
    input clk,
    input kbclk,
    input rst_n,
    input in,
    output [6:0] out0,
    output [6:0] out1,
    output [6:0] out2,
    output [6:0] out3
);

    wire deb_kbclk;
    deb deb_inst(.clk(clk), .rst_n(rst_n), .in(kbclk), .out(deb_kbclk));

    // value used for dsiplay
    reg [7:0] data_reg, data_next;
    reg [7:0] data_reg1, data_next1;

    // value used for changing value
    reg [7:0] next_reg, next_next;

    wire [3:0] display_reg0;
    wire [3:0] display_reg1;
    wire [3:0] display_reg2;
    wire [3:0] display_reg3;

    assign display_reg0 = data_reg[3:0];
    assign display_reg1 = data_reg[7:4];
    assign display_reg2 = data_reg1[3:0];
    assign display_reg3 = data_reg1[7:4];

    hex hex_inst0(.in(data_reg[3:0]), .out(out0)); //nulta cifra
    hex hex_inst1(.in(display_reg1), .out(out1));//prva cifra
    hex hex_inst2(.in(display_reg2), .out(out2));//druga cifra
    hex hex_inst3(.in(display_reg3), .out(out3));//treca cifra 

    integer cnt_reg, cnt_next;
    reg flag_reg, flag_next; 

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_reg <= 8'h00;
            data_reg1 <= 8'h00;
            next_reg <= 8'h00;
            cnt_reg<=0; 
            flag_reg<=1'b0; 
        end
        else begin
            data_reg <= data_next;
            data_reg1 <= data_next1;
            next_reg <= next_next;
            cnt_reg<=cnt_next;
            flag_reg<=flag_next;
        end
    end

    always @(negedge deb_kbclk) begin

        next_next = next_reg;
        cnt_next = cnt_reg; 
        flag_next = flag_reg;

        if(cnt_reg == 0 && in == 1'b0) begin
            cnt_next = cnt_reg + 1;
        end

        if(cnt_reg > 0 && cnt_reg < 9) begin
            next_next[cnt_reg - 1] = in;
            cnt_next = cnt_reg + 1;
        end

        if(cnt_reg == 9) begin
            flag_next = 1'b1;
            cnt_next = cnt_reg + 1;
        end

        if(cnt_reg == 10)begin
            flag_next = 1'b0;
            cnt_next = 0;
        end
        
    end

    always @(posedge flag_reg) begin
        data_next = data_reg;
        data_next1 = data_reg1;

        if(next_next == next_reg && next_next!=8'hF0)begin
            data_next = next_next;
        end
        else if(next_next == next_reg && next_next==8'hF0)begin
            data_next1 = next_next; 
        end

    end

endmodule
