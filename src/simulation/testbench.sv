`include "uvm_macros.svh"
import uvm_pkg::*;

class ps2_item extends uvm_sequence_item;

    rand bit in;
	rand bit kbclk;
    bit [6:0] out0;
    bit [6:0] out1;

    `uvm_object_utils_begin(reg8_item)
		`uvm_field_int(in, UVM_ALL_ON)
		`uvm_field_int(kbclk, UVM_ALL_ON)
		`uvm_field_int(out0, UVM_NOPRINT)
		`uvm_field_int(out1, UVM_NOPRINT)
	`uvm_object_utils_end

    function new(string name = "ps2_item");
        super.new(name)
    endfunction

    virtual function string my_print();

        return $sformatf(
			"in = %1b kbclk = %1b out0 = %7b out1 = %7b",
			in, kbclk, out0, out1
		); 

    endfunction

endclass

// Generator
class generator extends uvm_sequence;

    `uvm_object_utils_begin(generator)

    function new(string name = "generator");
        super.new(name)
    endfunction //new()

	// TODO
    int num = 200;
	virtual task body();
		for (int i = 0; i < num; i++) begin
			ps2_item item = ps2_item::type_id::create("item");
			start_item(item);	
			item.randomize();
			`uvm_info("Generator", $sformatf("Item %0d/%0d created", i + 1, num), UVM_LOW)
			item.print();
			finish_item(item);
		end
	endtask

endclass

// Driver
class driver extends uvm_driver #(ps2_item);

    `uvm_component_utils(driver)
	
	function new(string name = "driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction

    virtual ps2_if vif;

    virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_if", vif))
			`uvm_fatal("Driver", "No interface.")
	endfunction

    virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			ps2_item item;
			seq_item_port.get_next_item(item);
			`uvm_info("Driver", $sformatf("%s", item.my_print()), UVM_LOW)
			vif.in <= item.in;
			vif.kbclk <= item.kbclk;
			@(posedge vif.clk);
			seq_item_port.item_done();
		end
	endtask

endclass

// Monitor
class monitor extends uvm_monitor;
	
	`uvm_component_utils(monitor)

    function new(string name = "monitor", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;
	uvm_analysis_port #(ps2_item) mon_analysis_port;

    virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Monitor", "No interface.")
		mon_analysis_port = new("mon_analysis_port", this);
	endfunction

    virtual task run_phase(uvm_phase phase);	
		super.run_phase(phase);
		@(posedge vif.clk);
		forever begin
			ps2_item item = ps2_item::type_id::create("item");
			@(posedge vif.clk);
			item.in = vif.in;
			item.kbclk = vif.kbclk;
			item.out0 = vif.out0;
            item.out1 = vif.out1;
			`uvm_info("Monitor", $sformatf("%s", item.my_print()), UVM_LOW)
			mon_analysis_port.write(item);
		end
	endtask

endclass

// Agent
class agent extends uvm_agent;
	
	`uvm_component_utils(agent)
	
	function new(string name = "agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	driver d0;
	monitor m0;
	uvm_sequencer #(ps2_item) s0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		d0 = driver::type_id::create("d0", this);
		m0 = monitor::type_id::create("m0", this);
		s0 = uvm_sequencer#(ps2_item)::type_id::create("s0", this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		d0.seq_item_port.connect(s0.seq_item_export);
	endfunction
	
endclass

// Scoreboard
class scoreboard extends uvm_scoreboard;
	
	`uvm_component_utils(scoreboard)
	
	function new(string name = "scoreboard", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	uvm_analysis_imp #(ps2_item, scoreboard) mon_analysis_imp;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		mon_analysis_imp = new("mon_analysis_imp", this);
	endfunction
	
	// TODO
	bit [6:0] out0 = 7'h00;
	bit [6:0] out1 = 7'h00;
	bit current_state = 1'b0;
	bit [3:0] i = 4'h0;
	bit [7:0] data = 8'h00;

	virtual function write(ps2_item item);
		if (out0 == item.out0 && out1 == item.out1)
			`uvm_info("Scoreboard", $sformatf("PASS!"), UVM_LOW)
		else
			`uvm_error("Scoreboard", $sformatf("FAIL! expected_out0 = %8b, expected_out1 = %8b, 
			got_out0 = %8b", got_out1 = %8b, out0, out1, item.out0, item.out1))	// TODO
		
	// TODO
	// valjda se ovako pisu funckuje
	function bit[6:0] hex(int value);

		case (value)
			4'b0000: return ~7'h3F;
            4'b0001: return ~7'h06;
            4'b0010: return ~7'h5B;
            4'b0011: return ~7'h4F;
            4'b0100: return ~7'h66;
            4'b0101: return ~7'h6D;
            4'b0110: return ~7'h7D;
            4'b0111: return ~7'h07;
            4'b1000: return ~7'h7F;
            4'b1001: return ~7'h6F;
            4'b1010: return ~7'h77;
            4'b1011: return ~7'h7C;
            4'b1100: return ~7'h39;
            4'b1101: return ~7'h5E;
            4'b1110: return ~7'h79;
            4'b1111: return ~7'h71; 
		endcase

	endfunction
	
		// TODO
		// 0 came, state change, track output

		case (current_state)
			1'b0: begin
				if(item.in == 1'b0) begin
					data = 8'h00;
					current_state = 1'b1;
				end
			end 
			1'b1: begin
				data[i] == item.in;
				i = i + 1;

				if(i == 4'h8 && data != 8'hF0) begin
					out0 = hex(data[3:0]);
					out1 = hex(data[7:4]);
					// pogledati kako da se napravi funkcija za HEX da bi se postavili OUT i da se uporedjuju
				end
				else begin
					current_state = 1'b0;
				end

				i = 4'h0;

			end
		endcase

		

	endfunction
endclass

// Environment
class env extends uvm_env;
	
	`uvm_component_utils(env)
	
	function new(string name = "env", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	agent a0;
	scoreboard sb0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a0 = agent::type_id::create("a0", this);
		sb0 = scoreboard::type_id::create("sb0", this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		a0.m0.mon_analysis_port.connect(sb0.mon_analysis_imp);
	endfunction
	
endclass

// Test
class test extends uvm_test;

	`uvm_component_utils(test)
	
	function new(string name = "test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;

	env e0;
	generator g0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Test", "No interface.")
		e0 = env::type_id::create("e0", this);
		g0 = generator::type_id::create("g0");
	endfunction
	
	virtual function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		
		vif.rst_n <= 0;
		#20 vif.rst_n <= 1;
		
		g0.start(e0.a0.s0);
		phase.drop_objection(this);
	endtask

endclass

// Interface
interface ps2_if (
	input bit clk
);

    logic kbclk; 
	logic rst_n;
    logic in;
    logic [7:0] out0;
    logic [7:0] out1;

endinterface


module testbench;

    reg clk;

    ps2_if dut_if (
		.clk(clk)
	);

    ps2 dut (
		.clk(clk),
        .kbclk(dut_if.kbclk),
		.rst_n(dut_if.rst_n),
		.in(dut_if.in),
		.out0(dut_if.out0),
		.out1(dut_if.out1)
	);

    initial begin
		clk = 0;
		forever begin
			#10 clk = ~clk;
		end
	end

	initial begin
		uvm_config_db#(virtual ps2_if)::set(null, "*", "ps2_vif", dut_if);
		run_test("test");
	end

endmodule
