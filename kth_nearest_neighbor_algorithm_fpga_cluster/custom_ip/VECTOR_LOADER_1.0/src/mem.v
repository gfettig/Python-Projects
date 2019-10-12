
module mem_cntrl
    (
	input clk,
	input reset, 
	input start,
	input txn_done,
	input [1:0] fifo_full,
	input [31:0] read_data,
	input [15:0] vect_size, num_vects,
	output reg mem_done,
	output reg start_load,
	output reg fifo_we,
	output reg cntrl_reset,
	output reg error,
	output [31:0] read_index, 
	output [31:0] read_offset);

parameter NUM_PIPES = 2;

localparam  IDLE = 4'b0000, 
		 	DONE_TARGET = 4'b0001, 
		 	LOAD_TARGET = 4'b0010,
		 	STORE_TARGET = 4'b0011,
		 	DONE = 4'b0100, 
		 	READ_ERROR = 4'b0101;

reg [3:0] state, nextState;
reg [31:0] index, nextIndex;
reg [31:0] vect, nextVect;

assign read_index = index;
assign read_offset = (vect*vect_size + index) << 2;

assign full = &fifo_full;

always @(posedge clk) begin
	if (reset) begin
		state <= LOAD_TARGET;
		index <= 32'd0;
		vect <= 32'd0;
	end
	else begin 
		state <= nextState;
		index <= nextIndex;
		vect <= nextVect;
	end
end

always @(*) begin
	nextState = DONE_TARGET;
	nextIndex = index;
	nextVect = vect;
	mem_done = 1'b0;
	start_load = 1'b0;
	fifo_we = 1'b0;
	cntrl_reset = 1'b0;
	error = 1'b0;

	case(state)
		// IDLE: begin 
		// 	if (start == 1'b1 && reset == 1'b0 && full == 1'b0) begin 
		// 		start_load = 1'b1;
		// 		nextState = LOAD_TARGET;
		// 	end 
		// 	else begin 
		// 		nextState = IDLE;
		// 	end 
		// end 
		LOAD_TARGET: begin 
			if (start == 1'b1 && reset == 1'b0 && full == 1'b0) begin 
				cntrl_reset = 1'b0;
				start_load = 1'b1;
				if(txn_done == 1'b1)  
					nextState = STORE_TARGET;
				else 
					nextState = LOAD_TARGET;
			end 
			else begin 
				nextState = LOAD_TARGET;
				cntrl_reset = 1'b1;
			end 
		end 
		// STORE_TARGET: begin
		// 	nextState <= DONE_TARGET; 
		// 	fifo_we = 1'b1;
		// end
		STORE_TARGET: begin
			if(read_data == index)
				nextState <= DONE_TARGET;
			else 
				nextState <= READ_ERROR;
			fifo_we = 1'b1;
		end 
		DONE_TARGET: begin 
			cntrl_reset = 1'b1; 
			if (txn_done == 1'b1) 
				nextState = DONE_TARGET;
			else if ((index + 32'd1) < vect_size) begin
				nextState = LOAD_TARGET;
				nextIndex = index + 32'd1;
			end 
			// start loading next vector
			else if ((vect + 32'd1) < num_vects) begin 
				nextVect = vect + 32'd1;
				nextIndex = 32'd0;
				nextState = LOAD_TARGET;
				end 
			else begin 
				nextState = DONE;
			end 
		end
		// DONE_TARGET: begin 
		// 	cntrl_reset = 1'b0; 
		// 	if ((txn_done == 1'b0) && ((index + 32'd1) < vect_size)) begin
		// 		nextState = LOAD_TARGET;
		// 		nextIndex = index + 32'd1;
		// 	end 
		// 	else begin 
		// 		// start loading next vector
		// 		if (vect < 1) begin 
		// 			nextVect = vect + 32'd1;
		// 			nextIndex = 32'd0;
		// 			nextState = LOAD_TARGET;
		// 		end 
		// 		else begin 
		// 			nextState = DONE_TARGET;
		// 			mem_done = 1'b1;
		// 		end 
		// 	end 
		// end
		DONE: begin 
			nextState = DONE;
			mem_done = 1'b1;
		end 
		READ_ERROR: begin
			nextState = READ_ERROR;
			error = 1'b1;
		end
	endcase 
end

endmodule
