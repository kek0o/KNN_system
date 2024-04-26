`timescale 10ns/1ns
`include "distance_calculator.v"

module distance_calculator_tb;

reg clk, rst, ready;
reg [W-1:0] training_data [0:M-1][0:N-1];
reg [W-1:0] training_data_type;
reg [W-1:0] input_data [0:M-1][0:N-1];
wire [W-1:0] distance;
wire [W-1:0] data_type;
wire done;

parameter M=2, N=3, W=32;

distance_calculator #(M,N,W) uut(clk, rst, ready, training_data, training_data_type, input_data,distance, data_type, done);

// clk generation
initial begin
  clk = 1;
  forever #20 clk = ~clk;
end

// stimuli generation
initial begin
  training_data_type = $urandom_range(0,3);
  
  for (integer i=0; i<M; i=i+1) begin
      for (integer j=0; j<N; j=j+1) begin
        training_data[i][j]=$urandom_range(0,500);
        input_data[i][j]=$urandom_range(0,500);
      end
  end
end

initial
begin
  $dumpfile("distance_calculator_tb.vcd");
  $dumpvars;

  clk = 0;
  forever #20 clk = ~clk; //50MHz clock (20ns period)

  rst = 1; 
  #5
  rst = 0;

  training_data_type = $urandom_range(0,3);
  
  for (integer i=0; i<M; i=i+1) begin
      for (integer j=0; j<N; j=j+1) begin
        training_data[i][j]=$urandom_range(0,500);
        input_data[i][j]=$urandom_range(0,500);
      end
  end

  $display("training_data:");
  for (int i = 0; i < M; i = i + 1) begin
    for (int j = 0; j < N; j = j + 1) begin
      $display("training_data[%0d][%0d] = %0d", i, j, training_data[i][j]);
    end
  end
  $display("Training data type: %0d", training_data_type);

  $display("input_data:");
  for (int i = 0; i < M; i = i + 1) begin
    for (int j = 0; j < N; j = j + 1) begin
      $display("input_data[%0d][%0d] = %0d", i, j, input_data[i][j]);
    end
  end
  #10;
  $display("distance = %0f", distance); 
  $display("Data type = %0d", data_type);
end 

endmodule
