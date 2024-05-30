module bitonic_sort #(parameter L = 4, W = 16, TYPE_W = 3)(
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

generate begin : sorting_network
  if (L > 1) begin
    wire [W*(1<<L)-1:0] stage0_rslt;
    wire [TYPE_W*(1<<L)-1:0] stage0_type_rslt;
    wire stage0_valid;

    bitonic_sort #(.L(L-1),.W(W),.TYPE_W(TYPE_W)) bitonic_sort_inst_stage00 (
      .clk(clk),
      .rst(rst),
      .in_valid(in_valid),
      .ascending(ascending),
      .in(in[W*(1<<(L-1))-1:0]),
      .in_type(in_type[TYPE_W*(1<<(L-1))-1:0]),
      .out(stage0_rslt[W*(1<<(L-1))-1:0]),
      .out_type(stage0_type_rslt[TYPE_W*(1<<(L-1))-1:0]),
      .out_valid(stage0_valid)
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
      .out_valid()
    );

    n_item_bitonic_sorter #(.L(L),.W(W),.TYPE_W(TYPE_W)) bitonic_sort_inst_stage1 (
      .clk(clk),
      .rst(rst),
      .in_valid(stage0_valid),
      .ascending(ascending), 
      .in(stage0_rslt),
      .in_type(stage0_type_rslt),
      .out(out),
      .out_type(out_type),
      .out_valid(out_valid)
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
  );
  end
end
endgenerate
endmodule
