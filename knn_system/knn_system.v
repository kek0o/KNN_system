module knn_system #(parameter M = 2, N = 3, W = 16, MAX_ELEMENTS = 32, TYPE_W = 3, K = 7, L = 6)(
  input wire clk,
  input wire rst,
  input wire read_done,
  input wire [W*MAX_ELEMENTS-1:0] training_data,
  input wire [TYPE_W-1:0] training_data_type,
  input wire [W*MAX_ELEMENTS-1:0] input_data,
  output data_request,
  output done,
  output reg done_calc,
  output [TYPE_W-1:0] inferred_type,
  output inference_done
);
  // Distance calculator wires
  wire [W-1:0] distance;
  wire [TYPE_W-1:0] data_type;

  // Distance sort registers
  reg [W*(1<<L)-1:0] distance_array; 
  reg [TYPE_W*(1<<L)-1:0] type_array; 
  wire [W*(1<<L)-1:0] distance_array_sorted; 
  wire [TYPE_W*(1<<L)-1:0] type_array_sorted;
  wire valid_sort;

  // K-type registers
  wire [TYPE_W*K-1:0] k_nearest_neighbours_type; 

  // Module instances
  // Distance calculator instance
  distance_calculator #(.M(M),.N(N),.W(W),.MAX_ELEMENTS(MAX_ELEMENTS),.TYPE_W(TYPE_W)) distance_calculator_inst (
    .clk(clk), .rst(rst), .ready(read_done), .training_data(training_data), .training_data_type(training_data_type),
    .input_data(input_data), .distance(distance), .data_type(data_type), .done(done), .data_request(data_request));

  // Distance sort instance
  distance_sort #(.L(L),.W(W),.TYPE_W(TYPE_W)) distance_sort_inst (
    .clk(clk), .rst(rst), .done_calc(done_calc), .distance_array(distance_array), .type_array(type_array), 
    .distance_array_sorted(distance_array_sorted), .type_array_sorted(type_array_sorted), .valid_sort(valid_sort));

  // K_type instance
  k_type #(.K(K),.TYPE_W(TYPE_W)) k_type_inst (
    .clk(clk), .rst(rst), .valid_sort(valid_sort), .k_nearest_neighbours_type(k_nearest_neighbours_type),
    .inferred_type(inferred_type), .inference_done(inference_done));

  integer i, done_count;
  always @(posedge clk) begin
    if (rst) begin
      done_calc <= 1'b0;
      done_count <= 0;
      distance_array <= {W*(1<<L){1'b1}};
      type_array <= {TYPE_W*(1<<L){1'b0}};
    end else begin
      if (done) begin
        done_count <= done_count + 1;
        done_calc <= 1'b0;
        distance_array[(done_count+1)*W-1 -: W] <= distance;
        type_array[(done_count+1)*TYPE_W-1 -: TYPE_W] <= data_type;
      end
      if (done_count < (1<<L)) done_calc <= 1'b0;
      else begin
        done_calc <= 1'b1;
        done_count <= 0;
      end
    end
  end

  assign k_nearest_neighbours_type = type_array_sorted[TYPE_W*K-1:0];
endmodule

