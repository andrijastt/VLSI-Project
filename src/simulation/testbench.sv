`include "uvm_macros.svh"
import uvm_pkg::*;

// Sequence Item
class ps2_item extends uvm_sequence_item;

	randc bit kbclk;
	rand bit in;
	bit [7:0] out0;
	bit [7:0] out1;
	
	`uvm_object_utils_begin(ps2_item)
		`uvm_field_int(kbclk, UVM_DEFAULT | UVM_BIN)
		`uvm_field_int(in, UVM_ALL_ON)
		`uvm_field_int(out0, UVM_NOPRINT)
		`uvm_field_int(out1, UVM_NOPRINT)
	`uvm_object_utils_end
	
	function new(string name = "ps2_item");
		super.new(name);
	endfunction
	
	virtual function string my_print();
		return $sformatf(
			"kbclk = %1b in = %1b out0 = %7b out1 = %7b",
			kbclk, in, out0, out1
		);
	endfunction

endclass

// Sequence
class generator extends uvm_sequence;

	`uvm_object_utils(generator)
	
	function new(string name = "generator");
		super.new(name);
	endfunction
	
	int num = 20;
	
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
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Driver", "No interface.")
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			ps2_item item;
			seq_item_port.get_next_item(item);
			`uvm_info("Driver", $sformatf("%s", item.my_print()), UVM_LOW)
			vif.kbclk <= item.kbclk;
			vif.in <= item.in;
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
			item.kbclk = vif.kbclk;
			item.in = vif.in;
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
	
	//TODO
	bit [7:0] data = 8'h00;
	bit [7:0] ps2_out0 = 8'h00;
	bit [7:0] ps2_out1 = 8'h00;
	bit [4:0] ones_counter = 4'h0;

	bit odd_parity = 1'b0;
	bit negedge_happend = 1'b0;
	bit flag_kbclk = 1'b0; 
	bit kbclk_prev = 1'b0; 

	virtual function write(ps2_item item);

		// sada verovatno ovde saljemo bit po bit i vrsimo proveru
		/*
			Genereise 11bit-a, plus nonstop kbclk~
			1. Provera da li dolazi start bit
				Zatim 8bit dolaze kako dolaze nije bitno
			2. Provera da li je dobar odd parity
			3. Provera da li je dobar stop bit

			Generise se item -> provera kbclk == 1 && prover kbdat == 0
				Manualno posedismo kblkc = ~kbaclki ako je kbdat bio == 1 stavimo da je kbdat = 0

			cnt = 0
			
			# provera da je dosao prvi dobar start bit
			if item.in == 0 and item.kbclk == 1 and cnt == 0:
				cnt += 1
				ones_counter = 0			
			
			if cnt in range(1,8):
				data[cnt-1] = item.in
				cnt += 1
				if item.in == 1:
					ones_counter += 1
			
			# provea za odd_parity
			if cnt == 9:
				odd_parity = ones_ounter % 2;

			if item.in == 1 and cnt == 10:
				PASSED
			else:
				if odd_parity != item.in and cnt == 9:
					FAILED!
					flag_failed = 1
				else:
					if cnt < 10:
						cnt += 1
					else:
						FAILED!

			

		*/


		// if (ps2_out0 == item.out0 && ps2_out1 == item.out1 && ps2_out2 == item.out2 && ps2_out3 == item.out3)
			`uvm_info("Scoreboard", $sformatf("PASS!"), UVM_LOW)
		// else
		// 	`uvm_error("Scoreboard", $sformatf("FAIL! expected out0 = %7b out1 = %7b out2 = %7b out3 = %7b, 
		// 	got out0 = %7b out1 = %7b out2 = %7b out3 = %7b kbclk = %1b in = %1b", 
		// 	ps2_out0, ps2_out1, ps2_out2, ps2_out3, 
		// 	item.out0, item.out1, item.out2, item.out3,
		// 	item.kbclk, item.in))
	
		// if(flag_kbclk == 1'b0) begin
		// 	kbclk_prev = item.kbclk;
		// 	flag_kbclk = 1'b1;
		// end
		// else begin
		// 	if(item.kbclk == 1'b0 && kbclk_prev == 1'b1)
		// 		negedge_happend = 1'b1;
		// end

		// if(negedge_happend == 1'b1) begin
			
		// end

		// negedge_happend = 1'b0;

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

	logic rst_n;
	logic kbclk;
    logic in;
    logic [7:0] out0;
    logic [7:0] out1;

endinterface

// Testbench
module testbench;

	reg clk;
	
	ps2_if dut_if (
		.clk(clk)
	);
	
	ps2 dut (
		.clk(clk),
		.rst_n(dut_if.rst_n),
		.kbclk(dut_if.kbclk),
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
