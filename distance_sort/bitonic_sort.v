module bitonic_sort #(parameter L = 32, W = 16, TYPE_W = 3)(
  input wire clk,
  input wire rst,
  input wire in_valid,
  input wire ascending,
  input wire [W*(1<<L)-1:0] in
  input wire [TYPE_W*(1<<L)-1:0] in_type,
  output reg [W*(1<<L)-1:0] out,
  output reg [TYPE_W*(1<<L)-1:0] out_type,
  output reg out_valid
);

if (L > 1) begin
  wire [W*(1<<L)-1:0] stage0_rslt;
  wire [TYPE_W*(1<<L)-1:0] stage0_type_rslt;
  wire stage00_valid,stage01_valid;

  bitonic_sort #(.L(L-1),.W(W),.TYPE_W(TYPE_W)) bitonic_sort_inst_stage00 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .ascending(ascending),
    .in(in[W*(1<<(L-1))-1:0]),
    .in_type(in_type[W*(1<<(L-1))-1:0]),
    .out(stage_0_rslt[W*(1<<(L-1))-1]),
    .out_type(stage0_type_rslt[W*(1<<(L-1))-1]),
    .out_valid(stage00_valid)
  );

  bitonic_sort #(.L(L-1),.W(W),.TYPE_W(TYPE_W)) bitonic_sort_inst_stage01 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .ascending(~ascending), // descending
    .in(in[W*(1<<L)-1:W*(1<<(L-1))]),
    .in_type(in_type[TYPE_W*(1<<L)-1:TYPE_W*(1<<(L-1))]),
    .out(stage0_rslt[W*(1<<L)-1:W*(1<<(L-1))]),
    .out_type(stage0_type_rslt[TYPE_W*(1<<L)-1:TYPE_W*(1<<(L-1))]),
    .out_valid(stage01_valid)
  );

  assign valid_sort = stage00_valid & stage01_valid;

end else if (L == 1) begin

  sort_2 #(.W(W),.TYPE_W(TYPE_W)) sort_2_stage01 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .ascending(ascending),
    .in_0(distance_array[W-1:0]),
    .in_1(distance_array[2*W-1:W]),
    .in_0_type(distance_array_type[W-1:0])),
    .in_1_type(distance_array_type[2*W-1:W])),
    .out_0(distance_array_sorted[W-1:0]),
    .out_1(distance_array_sorted[2*W-1:0]),
    .out_0_type(distance_array_type[W-1:0]),
    .out_1_type(distance_array_type[2*W-1:0]),
    .out_valid(valid_sort)
);

end 
endmodule
