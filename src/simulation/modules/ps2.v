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

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_reg <= 8'h00;
            data_reg1 <= 8'h00;
            next_reg <= 8'h00;
            cnt_reg<=0; 
            flag_reg<=1'b0; 
            displFlag_reg<=2'b00; 
        end
        else begin
            data_reg <= data_next;
            data_reg1 <= data_next1;
            next_reg <= next_next;
            cnt_reg<=cnt_next;
            flag_reg<=flag_next; 
            displFlag_reg<=displFlag_next; 
        end
    end

    always @(negedge kbclk) begin

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
        displFlag_next=displFlag_reg;

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
        // else if(next_next == next_reg && next_next==8'hF0)begin
        //     data_next1 = next_next; 
        // end


    end

endmodule
