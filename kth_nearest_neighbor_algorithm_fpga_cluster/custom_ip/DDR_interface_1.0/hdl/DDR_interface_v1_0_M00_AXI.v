
`timescale 1 ns / 1 ps

	module M00_AXI #
	(
		// Width of M_AXI address bus
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		// Width of M_AXI data bus
		parameter integer C_M_AXI_DATA_WIDTH	= 32
	)
	(
		// Users to add ports here
		input start_txn, 
		input write_en, 
		input [C_M_AXI_DATA_WIDTH-1:0] write_data,
		input [C_M_AXI_DATA_WIDTH-1:0] txn_addr,
		output reg [31:0] read_data,

		// User ports ends
		// Do not modify the ports beyond this line

		// Initiate AXI transactions

		// Asserts when AXI transactions is complete
		output reg  TXN_DONE,
		output [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB, 
		output ERROR, 
		// AXI clock signal
		input wire  M_AXI_ACLK,
		// AXI active low reset signal
		input wire  M_AXI_ARESETN,
		// Master Interface Write Address Channel ports. Write address (issued by master)
		output reg [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Write channel Protection type.
    // This signal indicates the privilege and security level of the transaction,
    // and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Write address valid. 
    // This signal indicates that the master signaling valid write address and control information.
		output wire  M_AXI_AWVALID,
		// Write address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data Channel ports. Write data (issued by master)
		output reg [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. 
    // This signal indicates which byte lanes hold valid data.
		// Write valid. This signal indicates that valid write data and strobes are available.
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave can accept the write data.
		input wire  M_AXI_WREADY,
		// Master Interface Write Response Channel ports. 
    // This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Write response valid. 
    // This signal indicates that the channel is signaling a valid write response
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master can accept a write response.
		output wire  M_AXI_BREADY,
		// Master Interface Read Address Channel ports. Read address (issued by master)
		output reg [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Protection type. 
    // This signal indicates the privilege and security level of the transaction, 
    // and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_ARPROT,
		// Read address valid. 
    // This signal indicates that the channel is signaling valid read address and control information.
		output wire  M_AXI_ARVALID,
		// Read address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_ARREADY,
		// Master Interface Read Data Channel ports. Read data (issued by slave)
		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer.
		input wire [1 : 0] M_AXI_RRESP,
		// Read valid. This signal indicates that the channel is signaling the required read data.
		input wire  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can accept the read data and response information.
		output wire  M_AXI_RREADY
	);
	assign ERROR = 0;

	// Example State machine to initialize counter, initialize write transactions, 
	// initialize read transactions and comparison of read data with the 
	// written data words.
	parameter [2:0] IDLE = 3'b000, 
		INIT_WRITE   = 3'b001, 
		INIT_READ = 3'b010, 
		WAIT_READ = 3'b011, 
		GET_WRITE_DATA = 3'b100, 
		DONE = 3'b101;

	 reg [2:0] mst_exec_state;

	// AXI4LITE signals
	//write address valid
	reg  	axi_awvalid;
	//write data valid
	reg  	axi_wvalid;
	//read address valid
	reg  	axi_arvalid;
	//read data acceptance
	reg  	axi_rready;
	//write response acceptance
	reg  	axi_bready;
	//write address
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	//A pulse to initiate a write transaction
	reg  	start_write;
	//A pulse to initiate a read transaction
	reg  	start_read;
	//Asserts when a single beat write transaction is issued and remains asserted till the completion of write trasaction.
	reg  	write_issued;
	//Asserts when a single beat read transaction is issued and remains asserted till the completion of read trasaction.
	reg  	read_issued;
	//flag that marks the completion of write trasactions. The number of write transaction is user selected by the parameter C_M_TRANSACTIONS_NUM.
	reg  	write_done;
	//flag that marks the completion of read trasactions. The number of read transaction is user selected by the parameter C_M_TRANSACTIONS_NUM
	reg  	reads_done;
	// initiate transaction
	reg  	init_txn;


	// I/O Connections assignments

	assign M_AXI_AWPROT	= 3'b000;
	assign M_AXI_AWVALID	= axi_awvalid;
	//Write Data(W)
	assign M_AXI_WVALID	= axi_wvalid;
	//Set all byte strobes in this example
	assign M_AXI_WSTRB	= 4'b1111;
	//Write Response (B)
	assign M_AXI_BREADY	= axi_bready;

	assign M_AXI_ARVALID	= axi_arvalid;
	assign M_AXI_ARPROT	= 3'b001;
	//Read and Read Response (R)
	assign M_AXI_RREADY	= axi_rready;

	//--------------------
	//Write Address Channel
	//--------------------

	  always @(posedge M_AXI_ACLK)										      
	  begin                                                                        
	    //Only VALID signals must be deasserted during reset per AXI spec          
	    //Consider inverting then registering active-low reset for higher fmax     
	    if (M_AXI_ARESETN == 0 || init_txn == 1'b1)                                                   
	      begin                                                                    
	        axi_awvalid <= 1'b0;                                                   
	      end                                                                      
	      //Signal a new address/data command is available by user logic           
	    else                                                                       
	      begin                                                                    
	        if (start_write)                                                
	          begin                                                                
	            axi_awvalid <= 1'b1;                                         
	          end                                                                  
	     //Address accepted by interconnect/slave (issue of M_AXI_AWREADY by slave)
	        else if (M_AXI_AWREADY && axi_awvalid)                                 
	          begin                                                                
	            axi_awvalid <= 1'b0;                                               
	          end                                                                  
	      end                                                                      
	  end 


	//--------------------
	//Write Data Channel
	//--------------------

	always @(posedge M_AXI_ACLK)                                        
	begin                                                                         
	 if (M_AXI_ARESETN == 0  || init_txn == 1'b1)                                                    
	   begin                                                                     
	     axi_wvalid <= 1'b0;                                                    
	   end                                                                       
	 //Signal a new address/data command is available by user logic              
	 else if (start_write)                                                
	   begin                                                                     
	     axi_wvalid <= 1'b1;                                                     
	   end                                                           
	 //Data accepted by interconnect/slave (issue of M_AXI_WREADY by slave)      
	 else if (M_AXI_WREADY && axi_wvalid)
	   begin
	    axi_wvalid <= 1'b0;
	   end
	end


	//----------------------------
	//Write Response (B) Channel
	//----------------------------

	  always @(posedge M_AXI_ACLK)
	  begin
	    if (M_AXI_ARESETN == 0 || init_txn == 1'b1)
	      begin
	        axi_bready <= 1'b0;
	      end
	    // accept/acknowledge bresp with axi_bready by the master
	    // when M_AXI_BVALID is asserted by slave
	    else if (M_AXI_BVALID && ~axi_bready)
	      begin
	        axi_bready <= 1'b1;
	      end                                                              
	    // deassert after one clock cycle                                  
	    else if (axi_bready)                                               
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                              
	    // retain the previous value                                       
	    else                                                               
	      axi_bready <= axi_bready;                                        
	  end                                                                  
	                                                                                  
	                                                                                   
	  // A new axi_arvalid is asserted when there is a valid read address              
	  // available by the master. start_read triggers a new read                
	  // transaction                                                                   
	  always @(posedge M_AXI_ACLK)                                                     
	  begin                                                                            
	    if (M_AXI_ARESETN == 0 || init_txn == 1'b1)                                                       
	      begin                                                                        
	        axi_arvalid <= 1'b0;                                                       
	      end                                                                          
	    //Signal a new read address command is available by user logic                 
	    else if (start_read)                                                    
	      begin                                                                        
	        axi_arvalid <= 1'b1;                                                       
	      end                                                                          
	    //RAddress accepted by interconnect/slave (issue of M_AXI_ARREADY by slave)    
	    else if (M_AXI_ARREADY && axi_arvalid)                                         
	      begin                                                                        
	        axi_arvalid <= 1'b0;                                                       
	      end                                                                          
	    // retain the previous value                                                   
	  end                                                                              


	//--------------------------------
	//Read Data (and Response) Channel
	//--------------------------------

	//The Read Data channel returns the results of the read request 
	//The master will accept the read data by asserting axi_rready
	//when there is a valid read data available.
	//While not necessary per spec, it is advisable to reset READY signals in
	//case of differing reset latencies between master/slave.

	  always @(posedge M_AXI_ACLK)                                    
	  begin                                                                 
	    if (M_AXI_ARESETN == 0 || init_txn == 1'b1)                                            
	      begin                                                             
	        axi_rready <= 1'b0;                                             
	      end                                                               
	    // accept/acknowledge rdata/rresp with axi_rready by the master     
	    // when M_AXI_RVALID is asserted by slave                           
	    else if (M_AXI_RVALID && ~axi_rready)                               
	      begin                                                             
	        axi_rready <= 1'b1;                                             
	      end                                                               
	    // deassert after one clock cycle                                   
	    else if (axi_rready)                                                
	      begin                                                             
	        axi_rready <= 1'b0;                                             
	      end                                                               
	    // retain the previous value                                        
	  end                                                                   
	                 

	//--------------------------------
	//User Logic
	//--------------------------------

	//Address/Data Stimulus

	//Address/data pairs for this example. The read and write values should
	//match.
	//Modify these as desired for different address patterns.                                                     

	  //implement master command interface state machine
	  always @ ( posedge M_AXI_ACLK)
	  begin
	    if (M_AXI_ARESETN == 1'b0)
	      begin

	        mst_exec_state  <= IDLE;
	        init_txn <= 1'b0;

			start_write <= 1'b0;
			write_issued  <= 1'b0;
			M_AXI_AWADDR <= 32'd0;
			M_AXI_WDATA <= 32'd0;

	    	M_AXI_ARADDR <= 32'd0;
	        read_issued <= 1'b0;
	        start_read <= 1'b0;
	        read_data <= 32'h00000000;
	        TXN_DONE <= 1'b0;  
	      end
	    else
	      begin
	       // state transition
	        case (mst_exec_state)
	          	IDLE: begin 
		            if (start_txn == 1'b1) begin
		            	init_txn <= 1'b1;
		            	if (write_en == 1'b1) begin 
			                mst_exec_state  <= GET_WRITE_DATA; 
			                M_AXI_AWADDR <= txn_addr;	// grab address 
		                end 
		                else begin 
		                	mst_exec_state  <= INIT_READ;
		                	M_AXI_ARADDR <= txn_addr;  // grab address
	                	end 
		            end
	            end 
		        GET_WRITE_DATA: begin 
		        	init_txn <= 1'b0;
		        	mst_exec_state <= INIT_WRITE;
		        	M_AXI_WDATA <= write_data;
	        	end 
	          	INIT_WRITE: begin 
		            if (write_done) begin 
		                mst_exec_state <= IDLE;
		                TXN_DONE <= 1'b1;
                    end 
		            else begin
		            	mst_exec_state  <= INIT_WRITE;
		            	if (~axi_awvalid && ~axi_wvalid && ~M_AXI_BVALID && ~start_write && ~write_issued)
		            	  begin
		            	    start_write <= 1'b1;
		            	    write_issued  <= 1'b1;
		            	  end
		            	else if (axi_bready)
		            	  begin
		            	    write_issued  <= 1'b0;
		            	  end                     
		            	else
		            	  begin
		            	    start_write <= 1'b0; //Negate to generate a pulse      
		            	  end                                                             
		              end
              	end
              	INIT_READ: begin 
              		init_txn <= 1'b0;
              		mst_exec_state <= WAIT_READ;
              	end 
          		WAIT_READ:  begin
	            	if (reads_done) begin                                                                
	                	mst_exec_state <= DONE;    
	                	TXN_DONE <= 1'b1;                               
	               	end                                                                  
	             	else begin                                                          
	                	if (~axi_arvalid && ~M_AXI_RVALID && ~start_read && ~read_issued) begin                                                            
	                    	start_read <= 1'b1;                                     
	                    	read_issued  <= 1'b1;                                          
	                  	end
	                 	else if (axi_rready) begin                                         
	                     	read_issued  <= 1'b0;   
	                     	read_data <= M_AXI_RDATA;                                       
	                   	end                                                              
	                 	else begin                                                            
	                     	start_read <= 1'b0; //Negate to generate a pulse        
	                   	end                                                              
	               end    
               	end   
               	DONE: begin 
               		mst_exec_state <= DONE;
               	end                             
	        	default :
	        	begin                                                                  
	            	mst_exec_state  <= IDLE;
	            	TXN_DONE <= 1'b1;
            	end                                                                    
	        endcase                                                                     
	    end                                                                             
	  end //MASTER_EXECUTION_PROC                                                                      
	                                                                                    
	  always @(posedge M_AXI_ACLK)                                                      
	  begin                                                                             
	    if (M_AXI_ARESETN == 0 || init_txn == 1'b1)                                                         
	      write_done <= 1'b0;

	    else if (M_AXI_BVALID && axi_bready)                              
	      write_done <= 1'b1;                                                          
	    else                                                                            
	      write_done <= write_done;                                                   
	  end                                                                               
                                                                         
	always @(posedge M_AXI_ACLK) begin

	    if (M_AXI_ARESETN == 0 || init_txn == 1'b1)                                                         
	      reads_done <= 1'b0;                                                           
	                                                                                    
	    //The reads_done should be associated with a read ready response                
	    else if (M_AXI_RVALID && axi_rready)                               
	      reads_done <= 1'b1;                                                           
	    else                                                                            
	      reads_done <= reads_done;
     end                                                       
	// Add user logic here

	// User logic ends

	endmodule
