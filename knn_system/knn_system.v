module knn_system #(parameter M, N, W, MAX_ELEMENTS, TYPE_W, K, L)(
  input wire clk,
  input wire rst,
  input wire read_done,
  input wire [W-1:0] training_data [0:(M*N)-1],
  input wire [TYPE_W-1:0] training_data_type,
  input wire [W-1:0] input_data [0:(M*N)-1],
  output reg data_request,
  output reg done,
  output reg done_calc,
  output reg [TYPE_W-1:0] inferred_type,
  output reg inference_done
);
// Distance calculator wires
wire [W-1:0] distance;
wire [TYPE_W] data_type;

// Distance sort registers
reg [W-1:0] distance_array[0:L-1];
reg [TYPE_W-1:0] type_array[0:L-1];
wire [W-1:0] distance_array_sorted[0:L-1];
wire [TYPE_W-1:0] type_array_sorted[0:L-1];
wire valid_sort;

// K-type registers
reg [TYPE_W-1:0] k_nearest_neighbours_type [0:K-1];


// Module instances
// Distance calculator instance
distance_calculator #(.M(M),.N(N),.W(W),.MAX_ELEMENTS(MAX_ELEMENTS),.TYPE_W(TYPE_W)) distance_calculator_inst (
  .clk(clk), .rst(rst), .ready(read_done), .training_data(training_data), .training_data_type(training_data_type),
  .input_data(input_data), .distance(distance), .data_type(data_type), .done(done), .data_request(data_request));

// Distance sort instance
distance_sort #(.N(L),.W(W),.TYPE_W(TYPE_W)) distance_sort_inst (
  .clk(clk), .rst(rst), .done(done_calc), .distance_array(distance_array), .type_array(type_array), 
  .distance_array_sorted(distance_array_sorted), .type_array_sorted(type_array_sorted), .valid_sort(valid_sort));

// K_type instance
k_type #(.N(L),.W(W),.K(K),.TYPE_W(TYPE_W)) k_type_inst (
  .clk(clk), .rst(rst), .valid_sort(valid_sort), .k_nearest_neighbours_type(k_nearest_neighbours_type),
  .inferred_type(inferred_type), .inference_done(inference_done));

integer i, done_count;
always @(posedge clk) begin
  if (rst) begin
    done_calc <= 1'b0;
    done_count <= 0;
    for (i = 0; i < L; i = i + 1) begin
      distance_array[i] <= {W{1'b1}};
      type_array[i] <= {TYPE_W{1'b1}};
    end
  end else begin
    for (i = 0; i < K; i = i + 1) k_nearest_neighbours_type[i] = type_array_sorted[(L-1)-i]; // distance array is sorted in descending order
    if (done) begin
      done_count <= done_count + 1;
      done_calc <= 1'b0;
      distance_array[done_count] <= distance;
      type_array[done_count] <= data_type;
    end
    if (done_count < L) done_calc <= 1'b0;
    else begin
      done_calc <= 1'b1;
      done_count <= 0;
    end
  end
end
endmodule
