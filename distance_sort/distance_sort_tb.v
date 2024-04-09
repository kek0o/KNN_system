`timescale 1ns/1ps
`include "distance_sort.v"
`include "sort_2.v"

module distance_sort_tb;

reg [B-1:0] distance_array[0:N-1];
reg [B-1:0] type_array[0:N-1];

wire [B-1:0] distance_array_sorted[0:N-1];
wire [B-1:0] type_array_sorted[0:N-1];

integer i;
parameter N = 64, B = 32;

distance_sort #(N, B) uut(distance_array, type_array, distance_array_sorted, type_array_sorted);

initial
begin
  $dumpfile("distance_sort_tb.vcd");
  $dumpvars;

  for (i = 0; i < N; i = i + 1) begin
    distance_array[i] = $urandom_range(0,100);
    
    if (distance_array[i] < 20) type_array[i] = 3;
    else if (distance_array[i] < 40) type_array[i] = 5;
    else if (distance_array[i] < 60) type_array[i] = 2;
    else if (distance_array[i] < 80) type_array[i] = 1;
    else type_array[i] = 4;
  end
  $display("distance&type_array = [");
  for ( i = 0; i < N - 2 ; i = i + 1) begin
    $display("%0d, %0d, ", distance_array[i], type_array[i]);
  end
  $display("%0d, %0d]", distance_array[N-1], type_array[N-1]);

  #100

 $display("distance&type_array_sorted = [");
  for ( i = 0; i < N; i = i + 1) begin
    $display("%0d, %0d ", distance_array_sorted[i], type_array_sorted[i]);
  end

  #20 

  for ( i = 0; i < N; i = i + 1) begin
    distance_array[i] = i;
  end
   $display("distance_array = [");
  for ( i = 0; i < N; i = i + 1) begin
    $display("%0f,", distance_array[i]);
  end
  
  #100
     $display("distance_array_sorted = [");
  for ( i = 0; i < N; i = i + 1) begin
    $display("%0f,", distance_array_sorted[i]);
  end 

end

endmodule

