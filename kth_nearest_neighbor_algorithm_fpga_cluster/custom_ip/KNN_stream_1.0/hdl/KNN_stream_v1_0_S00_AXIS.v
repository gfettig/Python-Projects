
`timescale 1 ns / 1 ps

	module my_S00_AXIS #
	(
		// Users to add parameters here
		
		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_S_AXIS_TDATA_WIDTH	= 64
//		parameter integer NUMBER_OF_INPUT_WORDS = 31750
	)
	(
		// Users to add ports here
		input wire reset,
		input wire [31:0] NUMBER_OF_INPUT_WORDS,
		output reg KNN_en,
		// output reg [31:0] sum,
		//output reg [31:0] test_index,
        output reg [31:0] int_1,
        output reg [31:0] int_2,
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
	localparam [1:0] IDLE = 2'b00,        // This is the initial/idle state 

	                WRITE_FIFO  = 2'b01,  // In this state FIFO is written with the
	                                    // input stream data S_AXIS_TDATA 

                    ERROR = 2'b10;		// this state is reached when the input does not 
                    					// match expectations. 
	wire  	axis_tready;
	// State variable
	reg [1:0] mst_exec_state; 
   
	reg [15:0] index;
	reg rst;
	
	wire fifo_wren;

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
	    end  
	  else
	    case (mst_exec_state)
	      IDLE: 
	        // The sink starts accepting tdata when 
	        // there tvalid is asserted to mark the
	        // presence of valid streaming data 
	          if (S_AXIS_TVALID && (index <= NUMBER_OF_INPUT_WORDS-1))
	            begin
	              mst_exec_state <= WRITE_FIFO;
	              rst <= 1'b0;
	            end
	          else
	            begin
	              mst_exec_state <= IDLE;
	              rst <= 1'b0;
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
	          end
          ERROR: begin 
          	// an error has occured
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
	  else begin 
	  	//KNN_en <= 1'b0;
	    if (index <= NUMBER_OF_INPUT_WORDS-1)
	      begin
	        if (fifo_wren)
	          begin
	            // write pointer is incremented after every write to the FIFO
	            // when FIFO write signal is enabled.
	            index <= index + 1;
	            writes_done <= 1'b0;
	            // sum <= sum + S_AXIS_TDATA[31:0] + S_AXIS_TDATA[63:32];
	            //test_index <= test_index + 32'd1;
	            //KNN_en <= 1'b1;
	          end
	          if ((index == NUMBER_OF_INPUT_WORDS-1)|| S_AXIS_TLAST)
	            begin
	              // reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
	              // has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
	              writes_done <= 1'b1;
	            end
	      end  
      end
	end

	// FIFO write enable generation
	assign fifo_wren = S_AXIS_TVALID && axis_tready;

	// FIFO Implementation
//	genvar byte_index;
//	 generate 
//	   for(byte_index=0; byte_index<= (C_S_AXIS_TDATA_WIDTH/8-1); byte_index=byte_index+1)
//	   begin:FIFO_GEN

//	     reg  [(C_S_AXIS_TDATA_WIDTH/4)-1:0] stream_data_fifo [0 : NUMBER_OF_INPUT_WORDS-1];

//	     // Streaming input data is stored in FIFO

//	     always @( posedge S_AXIS_ACLK )
//	     begin
//	       if (fifo_wren)// && S_AXIS_TSTRB[byte_index])
//	         begin
//	           stream_data_fifo[index] <= S_AXIS_TDATA[(byte_index*8+7) -: 8];
//	         end  
//	     end  
//	   end		
//	 endgenerate

// Add user logic here
    //Each 'word' is 64 bits NOT 16 bits like default
    //index counts from 0 to NUMBER_OF_INPUT_WORDS-1, not really useful here
    //fifo_wren says when we can save incoming data
    
//    localparam dimensions = 10000;
    
    reg [31:0] testv;
    reg [31:0] trainv;
    reg newdata;
//    reg [63:0] testv [0 : dimensions/2-1]; //was 32 bits, could not write twice in a cycle
//    reg [63:0] trainv; //was 32 bits, hold 2 ints
//    reg [15:0] testpoint; //index to test vector
//    reg [15:0] testtail;  //index to read from test vector
//    reg trainhead; //tell if data is new
//    reg traintail; //output index from train vector
    //reg tf1, tf2;   //train full signals from input/output blocks
    
    //input data to test and train regs
    always@(posedge S_AXIS_ACLK)
    begin
        // Set FIFOs and pointers to 0
        if (reset) begin
            testv <= 32'b0;
            trainv <= 32'b0;
            newdata <= 1'b0;
//            testpoint <= 16'b0;
//            trainhead <= 1'b0;
            //tf1 <= 1'b0;
        end
        // If writing data from DMA...
        else if (fifo_wren) begin
            testv <= S_AXIS_TDATA[31:0];
            trainv <= S_AXIS_TDATA[63:32];
            newdata <= 1'b1;
            // Fill test vector first, 2 ints at a time
//            if (testpoint < dimensions) begin
//                testv[testpoint>>1] <= S_AXIS_TDATA;//[31:0]; no shift
                //testv[testpoint+1] <= S_AXIS_TDATA[63:32];
                
//                testpoint <= testpoint+2;
//            end
            // Fill train vector after test, if not full
//            else begin //if (!tf2) 
//                trainv <= S_AXIS_TDATA;//[31:0]; no shift
                //trainv[trainhead+1] <= S_AXIS_TDATA[63:32];
                
                // When head will equal tail, the vector is full
//                if ( (trainhead+2)%dimensions == traintail )
//                    tf1 <= 1'b1;
//                trainhead <= 1'b1;
//                trainhead <= (trainhead+2) % NUMBER_OF_INPUT_WORDS;
//            end
        end 
        else
            newdata <= 1'b0;
//        else if (traintail) //if outputting, reset bit
//            trainhead <= 1'b0;
    end
    
    //when available, output data and enable KNN on negedge
    always@(negedge S_AXIS_ACLK)
    begin
        // Set enable LOW when train vector is empty, or on initial reset
        if ( reset ) begin  // && !tf1)
            KNN_en <= 1'b0;
            int_1 <= 32'b0;
            int_2 <= 32'b0;
//            testtail <= 16'b0;
//            traintail <= 16'b0;
            //tf2 <= tf1;
        end
        // If none of those cases, send data to KNN
        else if(newdata) begin
            KNN_en <= 1'b1;
            int_1 <= testv;//[testtail>>1][32*testtail[0]+31 -: 32]; //use MSBs to index array, use LSb to select 32 bits of vector
            int_2 <= trainv;//[32*traintail+31 -: 32];
            
            // Vector cannot be full after data is output
            //tf2 <= 1'b0;
//            testtail <= (testtail+1) % dimensions;
//            traintail <= !traintail;
        end
        else
            KNN_en <= 1'b0;
    end
    
// User logic ends

endmodule
