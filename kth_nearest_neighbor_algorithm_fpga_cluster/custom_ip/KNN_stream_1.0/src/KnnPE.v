`timescale 1ns / 1ps
//Each KnnPE module handles the complete comparison of two vectors.
//The dimension data of each vector are input {size} elements at a time.
//This is repeated {total} times until the calculation is complete.

module KnnPE
#(
parameter size=1,       //number of comparisons completed each cycle
parameter total=10000   //number of cycles before done
)(
input clk,
input [(size * 32 - 1):0] test_data,
input [(size * 32 - 1):0] train_data,
output [127:0] echo,
output reg done,
output [31:0] dist  //sum of all comparisons
);

    wire [31:0] test [0:(size-1)];  //split input test data
    wire [31:0] train [0:(size-1)]; //split input train data
    reg [31:0] sum;                 //running sum of comparisons
    reg [15:0] count;               //count cycles up to total
    wire [31:0] sqrout [0:(size-1)];//comparison out from each APE
    wire [31:0] sqrsum [0:(size-1)];//cumulative sum of all outputs
    
    reg [31:0] echor [0:3];
    assign echo = {echor[3], echor[2], echor[1], echor[0]};
    
    genvar n;
    generate    //connect nets as per above definitions
        for (n=0; n<size; n=n+1) begin
            assign test[n] = test_data[(n*32+31):(n*32)];
            assign train[n] = train_data[(n*32+31):(n*32)];
            ArithPE pe(test[n], train[n], sqrout[n]);
            
            if (n == 0) begin
                assign sqrsum[0] = sqrout[0];
            end
            else begin
                assign sqrsum[n] = sqrsum[n-1] + sqrout[n];
            end
        end
    endgenerate
    
    //update output in real time
    assign dist = sum + sqrsum[size-1];
    
    initial begin
        sum <= 0;
        count <= 0;
    end
    
    always @ (posedge clk) begin
        //if reached total, reset
        if (count >= total) begin
            sum <= sqrsum[size-1];
            count <= 1;
        end
        //update sum and count
        else begin
            sum <= sum + sqrsum[size-1];
            count <= count + 16'b1;
        end
        
        case (count)
            16'b00: begin
                echor[0] <= train[0];
                echor[1] <= test[0];
            end
            16'b01: begin
                echor[2] <= train[0];
                echor[3] <= test[0];
            end
//            16'b10: echor[2] <= train[0];
//            16'b11: echor[3] <= train[0];
            default: begin
                echor[0] <= echor[0];
                echor[1] <= echor[1];
                echor[2] <= echor[2];
                echor[3] <= echor[3];
            end
        endcase
    end
    
    //preemtively set done on negedge
    always @ (negedge clk) begin
        if (count >= total-16'b1) begin
            done <= 1'b1;
        end
        else
            done <= 1'b0;
    end
    
endmodule
