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

    hex hex_inst0(.in(display_reg0), .out(out0)); //nulta cifra
    hex hex_inst1(.in(display_reg1), .out(out1));//prva cifra
    hex hex_inst2(.in(display_reg2), .out(out2));//druga cifra
    hex hex_inst3(.in(display_reg3), .out(out3));//treca cifra 

    reg [3:0] i;
    reg[2:0] byteCnt; 

    reg state_reg, state_next;

    localparam start = 1'b0;
    localparam data_transfer = 1'b1;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_reg <= 8'h00;
            data_reg1 <= 8'h00;
            next_reg <= 8'h00;
            i <= 4'h0;
            byteCnt<=3'h0; 
            state_reg <= start;
        end
        else begin
            data_reg <= data_next;
            data_reg1 <= data_next1;
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
                    else begin
                        byteCnt=3'h0; 
                    end
                end

                data_transfer: begin

                    if(i < 4'h8) begin
                        next_next[i] = in;
                    end

                    i = i + 4'h1;

                    // reset
                    if (i == 4'h8 && next_next != 8'hF0) begin
                        if(byteCnt == 0)begin
                            data_next = next_next;    
                        end
                        else if(byteCnt==1) begin
                            data_next1 = next_next; 
                        end
                        i = 4'h0;                        
                    end

                    if(i == 4'hA) begin
                        byteCnt = byteCnt+1; 
                        if(byteCnt == 1)begin
                            data_next = 8'h00;      // ne znam da li ovako da stavimo ili ne
                        end
                        else if(byteCnt==2) begin
                            data_next1 =8'h00; 
                        end
                        state_next = start;
                        i = 4'h0;
                    end
                end
            endcase
        end

    end

endmodule
