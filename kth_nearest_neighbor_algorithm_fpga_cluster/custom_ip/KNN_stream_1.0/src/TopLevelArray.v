`timescale 1ns / 1ps
/* Change parameters to fit application
This top-level module performs the knn algorithm on a set of input 
train vectors and train vector.  Datain is a combination of test and
train dimensions.  The most significant value is the test dim, the 
remaining are the train dims counting up towards the least significant.
Each dimension is a 32bit integer.  3 lists are used to store the knn
values.  The first two are cycled such that one can be adjusted while 
the other is sequentially output. The third is used to insertion sort 
and update the origional lists.  Both distance(near) and id(value) are 
kept in a list for functional verification.
*/

module TopLevelArray
#(
parameter k = 8,                //nearest neighbors
parameter knn_size = 1,         //data in size for knn modules, must be 1 (1 test dim each cycle)
//parameter train_vectors = 6,    //vectors to compare
parameter dimensions = 8,       //dimensions in each vector
parameter total = dimensions / knn_size,//total number of dim for each vector / input data for each knn
parameter datain_size = 4,      //values input at a time
parameter knns = datain_size - 1,//knnPEs generated
parameter dataout_size = 1     //values output at a time, output one every cycle
)(
input clk,
input [(32*datain_size - 1):0] datain,
input [31:0] train_vectors,
output [127:0] echo,
output reg done,
output [(32*dataout_size - 1):0] dataout,
output reg [31:0] valout//[(16*dataout_size - 1):0] valout //should nt be reg
);

    wire [(knn_size * 32 - 1):0] test_data;
    wire [(knn_size * 32 - 1):0] train_data [0:(knns-1)];
    
    //3 of the near and value arrays are made, first 2 to rotate each calculation cycle, last as a temp
    (*DONT_TOUCH="true"*)reg [31:0] near [0:2][0:(k-1)];   //array for k nearest distances
    (*DONT_TOUCH="true"*)reg [31:0] nout [0:(dataout_size-1)];   //array to output
    (*DONT_TOUCH="true"*)reg [15:0] value [0:2][0:(k-1)];  //array for k nearest counts
    (*DONT_TOUCH="true"*)reg [15:0] vout [0:(dataout_size-1)];   //inex to output
    
    wire pedone [0:(knns-1)];       //done bits for each knnPE
    wire [31:0] dist [0:(knns-1)];  //distance from each knn
    
    reg [7:0] h, i, j, w, x, y;       //counters
    reg [15:0] count;            //count up train vectors(*MARK_DEBUG="true"*)
    (*DONT_TOUCH="true"*)reg ksel;                   //select knn lists to insert and display

    //assign valout = count;
    //assign valout = dist[0];
    
    genvar n;
    generate
        for (n=0; n<knns; n=n+1) begin
            //create knnPEs
            KnnPE #(.size(knn_size),.total(total)) knn(.clk(clk),.test_data(test_data),.train_data(train_data[n]),.echo(echo),.done(pedone[n]),.dist(dist[n]));
        end
        
        //split test and train data from input
        assign test_data = datain[(32*datain_size-1):(32*(datain_size-1))];
        for (n=0; n<knns; n=n+1) begin
            assign train_data[n] = datain[((knns-n)*32-1):(32*(knns-n-1))];
        end
        
        //join distance and id for output
        for (n=0; n<dataout_size; n=n+1) begin
            assign dataout[(32*n+31):(32*n)] = nout[n];
//            assign valout[(16*n+15):(16*n)] = vout[n];
        end
    endgenerate
    
    initial begin
        //initialize regs
        for (i=0; i<k; i=i+1) begin
            near[0][i] <= 32'hffffffff;
            value[0][i] <= 16'hffff;
            near[1][i] <= 32'hffffffff;
            value[1][i] <= 16'hffff;
            near[2][i] <= 32'hffffffff;
            value[2][i] <= 16'hffff;
        end
        count <= 16'b0;
        done <= 1'b0;
        y <= 8'b0;
        ksel = 1'b0;
        valout <= 0; //delete this
    end
    
    always @ (posedge clk) begin
        //update knn values in temp list
        if (pedone[0]) begin
            if (count==1)  //delete these 2 lines
                valout <= dist[0];
            if (done) begin //reset values
                for (h=0; h<k; h=h+1) begin
                    near[2][h] = 32'hffffffff;
                    value[2][h] = 16'hffff;
                end
            end
            for (i=0; i<knns; i=i+1) begin
                for (j=0; j<k; j=j+1) begin
                    if (near[2][k-1-j] > dist[i]) begin
                        if (j>0) begin
                            near[2][k-j] = near[2][k-1-j];
                            value[2][k-j] = value[2][k-1-j];
                        end
                        near[2][k-1-j] = dist[i];
                        value[2][k-1-j] = count + {8'b0,i};
                    end
                end
            end
        end
        
    end
    
    always @ (negedge clk) begin
        if (pedone[0]) begin            
            //logic to update nearest neighbor array
            for (w=0; w<k; w=w+1) begin
                    near[ksel][w] <= near[2][w];
                    value[ksel][w] <= value[2][w];
            end
            
            //track status of knn algorithm
            if ( (count+knns)<train_vectors ) begin
                count <= count + knns;
                done <= 1'b0;
            end
            else begin
                count <= 16'b0;
                done <= 1'b1;
                ksel <= ~ksel;  //switch knn lists
            end
        end

        //output dataout_size data at a time when done
        if ( y>0 || (pedone[0] && (count+knns)>=train_vectors) ) begin
            for (x=0; x<dataout_size; x=x+1) begin
                nout[x] <= near[(y==0)? 2 : ~ksel][y+x];
                vout[x] <= value[(y==0)? 2 : ~ksel][y+x];
            end
            y <= (y + dataout_size)%k; //use to count data output
        end
        else begin
            for (x=0; x<dataout_size; x=x+1) begin
                nout[x] <= 32'bX;
                vout[x] <= 16'bX;
            end
            y <= 8'b0;
        end
    end
    
endmodule
