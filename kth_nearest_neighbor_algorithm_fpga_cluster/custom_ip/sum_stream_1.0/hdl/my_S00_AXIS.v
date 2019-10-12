
`timescale 1 ns / 1 ps

	module my_S00_AXIS #
	(
		// Users to add parameters here
		
		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here
		input wire reset,
		input wire [31:0] NUMBER_OF_INPUT_WORDS,
		output reg [31:0] sum,
		// User ports ends
		// Do not modify the ports beyond this line

		// AXI4Stream sink: Clock
		input wire  S_AXIS_ACLK,
		// AXI4Stream sink: Reset
		input wire  S_AXIS_ARESETN,
		// Ready to accept data in
		output wire  S_AXIS_TREADY,
		// Data in
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
		// Byte qualifier
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
		// Indicates boundary of last packet
		input wire  S_AXIS_TLAST,
		// Data is in valid
		input wire  S_AXIS_TVALID
	);

	// Define the states of state machine
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO
	parameter [1:0] IDLE = 2'b00,        // This is the initial/idle state 

	                WRITE_FIFO  = 2'b01,  // In this state FIFO is written with the
	                                    // input stream data S_AXIS_TDATA 

                    ERROR = 2'b10;		// this state is reached when the input does not 
                    					// match expectations. 
	wire  	axis_tready;
	// State variable
	reg [1:0] mst_exec_state; 
   
	reg [15:0] index;
	reg rst;

	// sink has accepted all the streaming data and stored in FIFO
	reg writes_done;
	// I/O Connections assignments

	assign S_AXIS_TREADY	= axis_tready;
	// Control state machine implementation
	always @(posedge S_AXIS_ACLK) 
	begin  
	  if (!S_AXIS_ARESETN || reset) 
	  // Synchronous reset (active low)
	    begin
	      mst_exec_state <= IDLE;
          rst <= 1'b1;
          sum <= 32'd0;
	    end  
	  else
	    case (mst_exec_state)
	      IDLE: 
	        // The sink starts accepting tdata when 
	        // there tvalid is asserted to mark the
	        // presence of valid streaming data 
	          if (S_AXIS_TVALID)
	            begin
	              mst_exec_state <= WRITE_FIFO;
	              rst <= 1'b0;
	            end
	          else
	            begin
	              mst_exec_state <= IDLE;
	            end
	      WRITE_FIFO: 
	        // When the sink has accepted all the streaming input data,
	        // the interface swiches functionality to a streaming master
	        if (writes_done) begin 
	            mst_exec_state <= IDLE;
	            rst <= 1'b1;
            end 
	        else
	          begin
	          	mst_exec_state <= WRITE_FIFO;
	          	sum <= sum + S_AXIS_TDATA;
	          end
          ERROR: begin 
          	// an erro has occured
          	mst_exec_state <= ERROR;
          end 
	    endcase
	end
	// AXI Streaming Sink 
	// 
	// The example design sink is always ready to accept the S_AXIS_TDATA  until
	// the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
	assign axis_tready = ((mst_exec_state == WRITE_FIFO) && (index <= NUMBER_OF_INPUT_WORDS-1));

	always@(posedge S_AXIS_ACLK)
	begin
	  if(!S_AXIS_ARESETN || reset || rst)
	    begin
	      index <= 0;
	      writes_done <= 1'b0;
	    end  
	  else
	    if (index <= NUMBER_OF_INPUT_WORDS-1)
	      begin
	        if (fifo_wren)
	          begin
	            // write pointer is incremented after every write to the FIFO
	            // when FIFO write signal is enabled.
	            index <= index + 1;
	            writes_done <= 1'b0;
	          end
	          if ((index == NUMBER_OF_INPUT_WORDS-1)|| S_AXIS_TLAST)
	            begin
	              // reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
	              // has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
	              writes_done <= 1'b1;
	            end
	      end  
	end

	// FIFO write enable generation
	assign fifo_wren = S_AXIS_TVALID && axis_tready;

	// FIFO Implementation
	// generate 
	//   for(byte_index=0; byte_index<= (C_S_AXIS_TDATA_WIDTH/8-1); byte_index=byte_index+1)
	//   begin:FIFO_GEN

	//     reg  [(C_S_AXIS_TDATA_WIDTH/4)-1:0] stream_data_fifo [0 : NUMBER_OF_INPUT_WORDS-1];

	//     // Streaming input data is stored in FIFO

	//     always @( posedge S_AXIS_ACLK )
	//     begin
	//       if (fifo_wren)// && S_AXIS_TSTRB[byte_index])
	//         begin
	//           stream_data_fifo[index] <= S_AXIS_TDATA[(byte_index*8+7) -: 8];
	//         end  
	//     end  
	//   end		
	// endgenerate

	// Add user logic here

	// User logic ends

	endmodule
