`timescale 10ns/1ns
`include "distance_sort.v"
`include "sort_2.v"

module distance_sort_tb;

reg clk, rst, done;
reg [W-1:0] distance_array[0:N-1];
reg [TYPE_W-1:0] type_array[0:N-1];

wire [W-1:0] distance_array_sorted[0:N-1];
wire [TYPE_W-1:0] type_array_sorted[0:N-1];
wire valid_sort;

integer i;
parameter N = 100, W = 32, TYPE_W = 3;

distance_sort #(N, W, TYPE_W) uut(clk, rst, done, distance_array, type_array, distance_array_sorted, type_array_sorted, valid_sort);

// clk generation
initial begin
  clk = 1;
  forever #20 clk = ~clk;
end

// task definition
task set_input_array(input integer range);
  for (i = 0; i < N; i = i + 1) begin 
    distance_array[i] = $urandom_range(0,range);
    
    if (distance_array[i] < 20) type_array[i] = 1;
    else if (distance_array[i] < 40) type_array[i] = 2;
    else if (distance_array[i] < 60) type_array[i] = 3;
    else if (distance_array[i] < 80) type_array[i] = 4;
    else type_array[i] = 5;
  end
  done = 1'b1;
  @(posedge clk);
  #1;
  done = 1'b0;
  wait (valid_sort);
  @(posedge clk);
  #1;
endtask

task display_array();
  wait(done);
  $display("distance&type_array = ");
  for ( i = 0; i < N; i = i + 1) $display("%0d, %0d, ", distance_array[i], type_array[i]);
  #200
  wait(valid_sort);
  $display("Sorted distance&type_array =");
  for ( i = 0; i < N; i = i + 1) $display("%0d, %0d, ", distance_array_sorted[i], type_array_sorted[i]);
endtask

//stimuli generation
initial begin
  rst = 1'b1;
  done = 1'b0;
  #5 rst = 1'b0;
  @(posedge clk);
  
  set_input_array(100);
  set_input_array(200);
  set_input_array(1000);
end

initial begin
  $dumpfile("distance_sort_tb.vcd");
  $dumpvars;
  
  display_array();
  display_array();
  display_array();
  
  #200 $finish;
end
endmodule

