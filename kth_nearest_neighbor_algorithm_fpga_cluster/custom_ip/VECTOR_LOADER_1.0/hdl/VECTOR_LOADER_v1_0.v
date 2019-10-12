
`timescale 1 ns / 1 ps

	module VECTOR_LOADER_v1_0 #
	(
		// Users to add parameters here

		parameter DATA_WIDTH = 32,
		parameter NUM_PIPES = 100,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		input clk, 
		input reset, 
		input ddr_txn_done, 
		input [NUM_PIPES-1:0] fifo_full,
		input [DATA_WIDTH-1:0] vect_size, num_vects,
		input [DATA_WIDTH-1:0] ddr_read_data, 
		input [DATA_WIDTH-1:0] ddr_base, 

		output start_load, 
		output done, 
		output fifo_we,
		output ddr_rst, 
		output read_error,
		output [DATA_WIDTH-1:0] ddr_addr, ddr_index, 
		// User ports ends
		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

	// Add user logic here
	wire [31:0] ddr_offset;

	assign ddr_addr = ddr_offset + ddr_base;
	
	mem_cntrl #(.NUM_PIPES(NUM_PIPES))
        ddr_reader(
        .clk(clk), 
        .reset(reset),
        .start(1'b1), 
        .txn_done(ddr_txn_done), 
        .mem_done(done), 
        .start_load(start_load), 
        .fifo_we(fifo_we), 
        .read_data(ddr_read_data), 
        .cntrl_reset(ddr_rst), 
        .read_index(ddr_index), 
        .read_offset(ddr_offset),
        .vect_size(vect_size),
        .num_vects(num_vects), 
        .error(read_error),
        .fifo_full(fifo_full));
	// User logic ends

	endmodule
