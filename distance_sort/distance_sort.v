module distance_sort #(parameter L = 64, W = 16, TYPE_W = 3)(
  input wire clk,
  input wire rst,
  input wire done_calc,
  input wire [W*L-1:0] distance_array,
  input wire [TYPE_W*L-1:0] type_array,
  output reg [W*L-1:0] distance_array_sorted,
  output reg [TYPE_W*L-1:0] type_array_sorted,
  output reg valid_sort
);

reg ascending;
assign ascending = 1'b1;

bitonic_sort #(.L(L),.W(W),.TYPE_W(TYPE_W)) bitonic_sort_inst(
  .clk(clk),
  .rst(rst),
  .in_valid(done_calc),
  .ascending(ascending),
  .in(distance_array),
  .in_type(type_array),
  .out(distance_array_sorted),
  .out_type(type_array_sorted),
  .out_valid(valid_sort)
);

endmodule
