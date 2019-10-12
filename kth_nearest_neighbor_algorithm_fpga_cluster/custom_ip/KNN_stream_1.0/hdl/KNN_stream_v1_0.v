
`timescale 1 ns / 1 ps

	module KNN_stream_v1_0 #
	(
		// Users to add parameters here
        parameter i = 2,    //int datainut at a time
        parameter d = 10000,    //dimensions
//        parameter t = 507,    //training vectors
        parameter k = 4,    //nearest neighbors
        parameter s = 1,    //APEs per KPE
        parameter p = d/s,  //iterations per KPE
        parameter z = i/s - 1,  //KPEs
        parameter o = 4,    //int output at once
        // User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 64
//        parameter integer NUMBER_OF_INPUT_WORDS = 160
	)
	(
		// Users to add ports here
		input wire reset, 
		input wire [31:0] packet_size,
        input wire [31:0] train_vectors,
		
		output wire done,
        output wire [31:0] int_1, 
        output wire [31:0] int_2, 
        output wire [31:0] int_3, 
        output wire [31:0] int_4,
		// User ports ends
		// Do not modify the ports beyond this line

		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid
	);
	localparam PACKET_WIDTH = C_S00_AXIS_TDATA_WIDTH >> 5;

	// Add user logic here
	wire knn_en, index, cycles;
	wire [31:0] latency;
    wire [(32*o - 1):0] dataout;
    //wire [(16*o - 1):0] valout;
    wire [(32*i - 1):0] datain;	
    wire [31:0] testd;
    wire [31:0] traind;
    wire clk;
    reg [2:0] clkcnt = 2'b0;
    
    wire [31:0] valout;       
    wire [127:0] echo;
    
    //use 2bit counter to make systolic clock 4 times slower
    always @ (posedge s00_axis_aclk) begin
        if (!s00_axis_aresetn)
            clkcnt <= 2'b0;
        else if (clk || (clkcnt > 0))
            clkcnt <= clkcnt + 3'b01;
    end
    
    //stop knn array when done or not enabled
    assign clk = (clkcnt > 0) ? 1'b1 : knn_en & (~done) & s00_axis_aclk;
    //move data from DMA regs to KNN arrays
    assign datain = {testd, traind};
    
    assign int_1 = echo[31:0];//dataout[31:0];
    assign int_2 = echo[63:32];//dataout[63:32];
    assign int_3 = echo[95:64];//dataout[95:64];
    assign int_4 = echo[127:96];//valout;//dataout[127:96];
    
//    initial x <= 32'b0;
//    always @ (posedge s00_axis_aclk) x <= x+32'b1;
    
    //Dan's KNN Systollic Array
    TopLevelArray #(.k(k),
                    .knn_size(s),
//                    .train_vectors(t),
                    .dimensions(d),
                    .total(p),
                    .datain_size(i),
                    .knns(i-1),
                    .dataout_size(o) )
                tla(.clk(clk),
                    .datain(datain),
                    .train_vectors(train_vectors),
                    .echo(echo),
                    .done(done),
                    .dataout(dataout),
                    .valout(valout) );
                    	
	my_S00_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
//        .NUMBER_OF_INPUT_WORDS(NUMBER_OF_INPUT_WORDS)
	) sum_stream_v1_0_S00_AXIS_inst (
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid), 
		
		.reset(reset),
		.NUMBER_OF_INPUT_WORDS(packet_size),
		.KNN_en(knn_en),
		.int_1(testd),
        .int_2(traind)
	);
    //PACKET WIDTH IS 2
    //WORD SIZE IS 64
	//assign done = (index*PACKET_WIDTH >= num_words);

	// User logic ends
//	thread thread0(
//		.clock(~s00_axis_aclk), 
//		.reset(reset), 
//		.en(knn_en), 
//        .dataIn(s00_axis_tdata),
//        .int_1(),
//        .int_2());

	cycleCount c0(
		.clock(s00_axis_aclk), 
		.reset(1'b0), 
		.en(1'b1),
		.count(latency));

	cycleCount c1(
		.clock(s00_axis_aclk), 
		.reset(reset), 
		.en((index < 32'd10000) && (index > 32'd0)),
		.count(cycles));

endmodule

module thread#(
		parameter integer DATA_WIDTH = 64
	)
	(
	input clock, 
	input reset, 
	input en, 
	input [DATA_WIDTH-1:0] dataIn,
	output reg [31:0] int_1,
	output reg [31:0] int_2);

	always @(posedge clock or posedge reset) begin
		if (reset) begin
			int_1 <= 32'd0;
			int_2 <= 32'd0;

		end
		else if (en) begin
			int_1 <= dataIn[31:0];
            int_2 <= dataIn[63:32];
      
		end
	end

endmodule

module cycleCount(
	input clock, 
	input reset, 
	input en,
	output reg [31:0] count
	);

    initial count <= 32'b0;
    
	always @(posedge clock) begin
		if (reset) begin
			count <= 32'b0;
		end
		else if (en) begin
			count <= count + 32'b1;
		end
	end

endmodule