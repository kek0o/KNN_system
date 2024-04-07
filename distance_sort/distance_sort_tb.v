`timescale 1ns/1ps
`include "distance_sort.v"
`include "sort_2.v"

module distance_sort_tb;

reg real distance_array[0:N-1];
wire real distance_array_sorted[0:N-1];
integer i;
parameter N = 64;

distance_sort #(N) uut(distance_array, distance_array_sorted);

initial
begin
  $dumpfile("distance_sort_tb.vcd");
  $dumpvars;

  for (i = 0; i < N; i = i + 1) begin
    distance_array[i] = $random;
  end
  $display("distance_array = [");
  for ( i = 0; i < N - 1 ; i = i + 1) begin
    $display("%0f, ", distance_array[i]);
  end
  $display("%0f]", distance_array[N]);

  #100

 $display("distance_array_sorted = [");
  for ( i = 0; i < N; i = i + 1) begin
    $display("%0f, ", distance_array_sorted[i]);
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

