`include "uvm_macros.svh"
import uvm_pkg::*;

class ps2_item extends uvm_sequence_item;

    rand bit in;
    bit [6:0] out0;
    bit [6:0] out1;

    `uvm_object_utils_begin(reg8_item)
		`uvm_field_int(in, UVM_DEFAULT)
		`uvm_field_int(out0, UVM_ALL_ON)
		`uvm_field_int(out1, UVM_NOPRINT)
	`uvm_object_utils_end

    function new(string name = "ps2_item");
        super.new(name)
    endfunction

    virtual function string my_print();

        return $sformatf(
			"in = %1b out0 = %7b out1 = %7b",
			in, out0, out1
		); 

    endfunction

endclass

// Generator
class generator extends uvm_sequence;

    `uvm_object_utils_begin(generator)

    function new(string name = "generator");
        super.new(name)
    endfunction //new()

    virtual task body();
        // TODO
    endtask //body //generator extends uvm_sequences

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
// gde treba kbclk?
// u zagrade ili ne
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

    // TODO
    ps2_if dut_if (
		.clk(clk)
	);

    //TODO
    ps2 dut (
		.clk(clk),
        .kbclk(dut_if.kbclk),
		.rst_n(dut_if.rst_n),
		.ld(dut_if.ld),
		.inc(dut_if.inc),
		.in(dut_if.in),
		.out(dut_if.out)
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
