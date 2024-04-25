`timescale 1ns/1ps
`include "knn_system.v"
`include "distance_sort.v"
`include "sort_2.v"
`include "distance_calculator.v"

module knn_system_tb;

reg clk, rst, start, ready;
reg [0:M-1][0:N-1][W-1:0] training_data [0:L-1];
reg [W-1:0] training_data_type [0:L-1];
reg [W-1:0] input_data [0:M-1][0:N-1];
wire [W-1:0] distance_array_sorted [0:L-1];
wire [W-1:0] type_array_sorted [0:L-1];
wire read;

parameter M = 2, N = 3, W = 32, K = 7, L = 15;

knn_system #(M,N,W,K,L) uut(clk, rst, start, ready, training_data, training_data_type, input_data, distance_array_sorted, type_array_sorted, read);

initial
begin
  $dumpfile("knn_system_tb.vcd");
  $dumpvars;

  clk = 0;
  forever #5 clk = ~clk;

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
end

endmodule
