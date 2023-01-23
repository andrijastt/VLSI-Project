module ps2(
    input clk,
    input kbclk,
    input rst_n,
    input in,
    output [7:0] out0,
    output [7:0] out1
);

    // value used for dsiplay
    reg [7:0] data_reg, data_next;
    reg [7:0] data_reg1, data_next1;

    assign out0 = data_reg;
    assign out1 = data_reg1;

    // value used for changing value
    reg [7:0] next_reg, next_next;

    integer cnt_reg, cnt_next;
    reg [1:0] displFlag_reg, displFlag_next; 
    reg flag_reg, flag_next; 
    reg parity_reg, parity_next; 
    reg stop_reg, stop_next; 
    reg helper;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_reg <= 8'h00;
            data_reg1 <= 8'h00;
            next_reg <= 8'h00;
            cnt_reg<=0; 
            flag_reg<=1'b0; 
            parity_reg<=1'b0; 
            stop_reg<=1'b0; 
            displFlag_reg<=2'b00; 
        end
        else begin
            data_reg <= data_next;
            data_reg1 <= data_next1;
            next_reg <= next_next;
            cnt_reg<=cnt_next;
            flag_reg<=flag_next; 
            parity_reg<=parity_next; 
            stop_reg<=stop_next; 
            displFlag_reg<=displFlag_next; 
        end
    end

    always @(negedge kbclk) begin

        next_next = next_reg;
        cnt_next = cnt_reg; 
        flag_next = flag_reg;
        parity_next = parity_reg;
        stop_next = stop_reg;

        if(cnt_reg == 0 && in == 1'b0) begin
            cnt_next = cnt_reg + 1;
            stop_next = 1'b0;
            parity_next = 1'b0;
        end

        if(cnt_reg > 0 && cnt_reg < 9) begin
            next_next[cnt_reg - 1] = in;
            cnt_next = cnt_reg + 1;
        end

        if(cnt_reg == 9) begin
            flag_next = 1'b1;
            helper = ^next_next;
            if(in == helper) begin
                parity_next = 1'b1;
            end
            cnt_next = cnt_reg + 1;
        end

        if(cnt_reg == 10)begin
            flag_next = 1'b0;
            if(in == 1'b0) begin
                stop_next = 1'b1;
            end
            cnt_next = 0;
        end
        
    end

    always @(posedge flag_reg) begin
        data_next = data_reg;
        data_next1 = data_reg1;
        displFlag_next=displFlag_reg;

        if(parity_reg || stop_reg) begin
            data_next = 8'hFF;
            data_next1 = 8'hFF;
        end
        else begin
            if(displFlag_reg==2'b00 && next_next!=8'hF0)begin

                if(next_next == 8'hE0 || next_next == 8'hE1) begin
                    data_next1 = next_next;
                    data_next = 8'h00;
                end
                else begin
                    data_next = next_next;
                    data_next1 = 8'h00; 

                end
                displFlag_next=2'b01; 
            end
            else 
            if(displFlag_reg==2'b01)begin

                if((data_reg == next_next && next_next!=8'hF0) || data_reg == 8'h00)begin
                    if(next_next == 8'h12 && data_reg1 == 8'hE0) begin
                        data_next = 8'h7C;
                        data_next1 = 8'hE0;
                    end
                    else
                    if(next_next == 8'h14 && data_reg1 == 8'hE1) begin
                        data_next = 8'h77;
                        data_next1 = 8'hF0;
                    end 
                    else
                    if(next_next != 8'hF0)
                        data_next = next_next;
                end 
                else begin
                    if(data_reg1==8'h00) begin
                        data_next1 = next_next;
                    end
                end

                if(next_next==8'hF0)begin
                    displFlag_next=2'b11;
                end
            end
            else begin
                displFlag_next=2'b00;
            end
        end

    end

endmodule
