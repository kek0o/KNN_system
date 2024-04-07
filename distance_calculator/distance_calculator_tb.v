`timescale 1ns/1ps
`include "distance_calculator.v"

module distance_calculator_tb;

reg [B-1:0] training_data [0:M-1][0:N-1];
reg [B-1:0] input_data [0:M-1][0:N-1];
wire real distance;
parameter M=2, N=3, B=32;

distance_calculator #(M,N,B) uut(training_data, input_data,distance);

initial
begin
  $dumpfile("distance_calculator_tb.vcd");
  $dumpvars;
  
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

  $display("input_data:");
  for (int i = 0; i < M; i = i + 1) begin
    for (int j = 0; j < N; j = j + 1) begin
      $display("input_data[%0d][%0d] = %0d", i, j, input_data[i][j]);
    end
  end
  #10;
  $display("distance = %0f", distance);
end 

endmodule
