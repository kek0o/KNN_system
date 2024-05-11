`timescale 10ns/1ns
`include "distance_sort.v"
`include "sort_2.v"

module distance_sort_tb;

reg clk, rst, validating_data;
reg [B-1:0] distance_array[0:N-1];
reg [B-1:0] type_array[0:N-1];

wire [B-1:0] distance_array_sorted[0:N-1];
wire [B-1:0] type_array_sorted[0:N-1];
wire valid_sort;

integer i;
parameter N = 64, B = 32;

distance_sort #(N, B) uut(clk, rst, validating_data, distance_array, type_array, distance_array_sorted, type_array_sorted, valid_sort);

// clk generation
initial begin
  clk = 1;
  forever #20 clk = ~clk;
end

//stimuli generation
initial begin
  
  rst = 1;
  validating_data= 0;
  #15 rst = 0;

  for (i = 0; i < N; i = i + 1) begin
    distance_array[i] = $urandom_range(0,100);
    
    if (distance_array[i] < 20) type_array[i] = 3;
    else if (distance_array[i] < 40) type_array[i] = 5;
    else if (distance_array[i] < 60) type_array[i] = 2;
    else if (distance_array[i] < 80) type_array[i] = 1;
    else type_array[i] = 4;
  end
  
  #20 validating_data = 1;
  #2000 validating_data = 0;

  $display("distance&type_array = [");
  for ( i = 0; i < N - 2 ; i = i + 1) begin
    $display("%0d, %0d, ", distance_array[i], type_array[i]);
  end
  $display("%0d, %0d]", distance_array[N-1], type_array[N-1]);

  #150

  for ( i = 0; i < N; i = i + 1) begin
    distance_array[i] = i;
  end

  #20 validating_data = 1;
  #2000 validating_data = 0;
  
  $display("distance_array = [");
  for ( i = 0; i < N; i = i + 1) begin
    $display("%0f,", distance_array[i]);
  end
end

initial begin
  $dumpfile("distance_sort_tb.vcd");
  $dumpvars;

  #2200
 $display("distance&type_array_sorted = [");
  for ( i = 0; i < N; i = i + 1) begin
    $display("%0d, %0d ", distance_array_sorted[i], type_array_sorted[i]);
  end
  
  #3000

  $display("distance_array_sorted = [");
  for ( i = 0; i < N; i = i + 1) begin
    $display("%0f,", distance_array_sorted[i]);
  end

  #20
  $finish;
end
endmodule

