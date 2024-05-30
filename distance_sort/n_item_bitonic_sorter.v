module n_item_bitonic_sorter #(parameter L = 64, W = 16, TYPE_W = 3)(
  input clk,
  input rst,
  input in_valid,
  input ascending,
  input [W*(1<<L)-1:0] in,
  input [TYPE_W*(1<<L)-1:0] in_type,
  output [W*(1<<L)-1:0] out,
  output [TYPE_W*(1<<L)-1:0] out_type,
  output out_valid
);

if (L > 1) begin
  wire [W*(1<<L)-1:0] stage0_rslt;
  wire [TYPE_W*(1<<L)-1:0] stage0_type_rslt;
  wire stage0_valid;

  genvar i;
  for (i = 0; i < (1<<(L-1)); i = i + 1) begin : stage0
    sort_2 #(.W(W),.TYPE_W(TYPE_W)) sort_2_stage01 (
      .clk(clk),
      .rst(rst),
      .in_valid(in_valid),
      .ascending(ascending),
      .in_0(in[W*(i+1)-1:W*i]),
      .in_1(in[W*(i+1+(1<<(L-1)))-1:W*(i+(1<<(L-1)))]),
      .in_0_type(in_type[TYPE_W*(i+1)-1:TYPE_W*i]),
      .in_1_type(in_type[TYPE_W*(i+1+(1<<(L-1)))-1:TYPE_W*(i+(1<<(L-1)))]),
      .out_0(stage0_rslt[W*(i+1)-1:W*i]),
      .out_1(stage0_rslt[W*(i+1+(1<<(L-1)))-1:W*(i+(1<<(L-1)))]),
      .out_0_type(stage0_type_rslt[TYPE_W*(i+1)-1:TYPE_W*i]),
      .out_1_type(stage0_type_rslt[TYPE_W*(i+1+(1<<(L-1)))-1:TYPE_W*(i+(1<<(L-1)))]),
      .out_valid(stage0_valid)
    );
  end

  n_item_bitonic_sorter #(.L(L-1),.W(W),.TYPE_W(TYPE_W)) n_sort_inst_stage10 (
    .clk(clk),
    .rst(rst),
    .in_valid(stage0_valid),
    .ascending(ascending),
    .in(stage0_rslt[W*(1<<(L-1))-1:0]),
    .in_type(stage0_type_rslt[TYPE_W*(1<<(L-1))-1:0]),
    .out(out[W*(1<<(L-1))-1:0]),
    .out_type(out_type[TYPE_W*(1<<(L-1))-1:0]),
    .out_valid(out_valid)
  );

  n_item_bitonic_sorter #(.L(L-1),.W(W),.TYPE_W(TYPE_W)) n_sort_inst_stage11 (
    .clk(clk),
    .rst(rst),
    .in_valid(stage0_valid),
    .ascending(ascending),
    .in(stage0_rslt[W*(1<<L)-1:W*(1<<(L-1))]),
    .in_type(stage0_type_rslt[TYPE_W*(1<<L)-1:TYPE_W*(1<<(L-1))]),
    .out(out[W*(1<<L)-1:W*(1<<(L-1))]),
    .out_type(out_type[TYPE_W*(1<<L)-1:TYPE_W*(1<<(L-1))]),
    .out_valid()
  );
end else if (L == 1) begin
  sort_2 #(.W(W),.TYPE_W(TYPE_W)) sort_2_stage01 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .ascending(ascending),
    .in_0(in[W-1:0]),
    .in_1(in[2*W-1:W]),
    .in_0_type(in_type[TYPE_W-1:0]),
    .in_1_type(in_type[2*TYPE_W-1:TYPE_W]),
    .out_0(out[W-1:0]),
    .out_1(out[2*W-1:W]),
    .out_0_type(out_type[TYPE_W-1:0]),
    .out_1_type(out_type[2*TYPE_W-1:TYPE_W]),
    .out_valid(out_valid)
);end
endmodule
