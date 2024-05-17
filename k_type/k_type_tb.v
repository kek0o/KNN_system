`timescale 10ns/1ns;
`include "k_type.v"

module k_type_tb;

reg clk, rst, valid_sort;
reg [TYPE_W-1:0] k_nearest_neighbours_type [0:K-1];
wire [TYPE_W-1:0] inferred_type;
wire inference_done;
integer i;

parameter N=10, W=32, K=5, TYPE_W = 4;

k_type #(N,W,K,TYPE_W) uut(clk, rst, valid_sort, k_nearest_neighbours_type, inferred_type, inference_done);

// clk generation
initial begin
  clk = 1;
  forever #20 clk = ~clk;
end

// task definition
task set_type_array();
  for (i = 0; i < K; i = i + 1) k_nearest_neighbours_type[i] = $urandom_range(0,10);
  valid_sort = 1'b1;
  @(posedge clk);
  #1;
  valid_sort = 1'b0;
  wait(inference_done);
  @(posedge clk);
  #1;
endtask

task display_type_array();
  wait(valid_sort)
  $display("Type array:");
  for(i = 0; i < K; i = i + 1) $display("k_nearest_neighbours_type[%0d] = %0d", i, k_nearest_neighbours_type[i]);
  wait (inference_done);
  $display("Inferred type: %0d", inferred_type);
endtask

//stimuli generation
initial begin
  rst = 1'b1;
  valid_sort = 1'b0;
  #5 rst = 1'b0;
  @(posedge clk);

  set_type_array();
  set_type_array();
  set_type_array();
end

initial begin
  $dumpfile("k_type_tb.vcd");
  $dumpvars;
  
  display_type_array();
  display_type_array();
  display_type_array();

  #2000 $finish;
end

endmodule