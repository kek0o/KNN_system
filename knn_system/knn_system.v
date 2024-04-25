module knn_system #(parameter M, N, W, K, L)(
  input wire clk,
  input wire rst,
  input wire start,
  input wire ready,
  input wire [W-1:0] training_data [0:L-1][0:M-1][0:N-1],
  input wire [W-1:0] training_data_type [0:L-1],
  input wire [W-1:0] input_data[0:M-1][0:N-1],
  output reg [W-1:0] distance_array_sorted[0:L-1],
  output reg [W-1:0] type_array_sorted[0:L-1],
  output reg read
);

parameter IDLE = 0, READ = 1, DIST = 2, SORT = 3;

genvar i;
integer index;

wire [W-1:0] distance_array [0:L-1];
wire [W-1:0] data_type_array [0:L-1];
reg [W-1:0] distance_array_valid [0:L-1];
reg [W-1:0] data_type_array_valid [0:L-1];
reg [W-1:0] distance_array_sorted_valid [0:L-1];
reg [W-1:0] type_array_sorted_valid [0:L-1];
reg [1:0] state;

generate 
  for (i = 0; i < L; i = i + 1) begin : DISTANCE_ARRAY_CALC
    distance_calculator #(M,N,W) distance_calculator_inst(.training_data(training_data[i]), .training_data_type(training_data_type[i]),
      .input_data(input_data), .distance(distance_array[i]), .data_type(data_type_array[i]));
  end
endgenerate


distance_sort #(N,W) distance_sort_inst (.distance_array(distance_array_valid), .type_array(data_type_array_valid),
.distance_array_sorted(distance_array_sorted_valid), .type_array_sorted(type_array_sorted_valid));

always @(state)
  begin
    case (state)
      IDLE:
        read = 1;
      READ: 
        read = 0;
      DIST:
        for (index = 0; index < L; index = index + 1) begin
          distance_array_valid[index] = distance_array[index];
          data_type_array_valid[index] = data_type_array[index];
        end
      SORT:
        for (index = 0; index < L; index = index + 1) begin
          distance_array_sorted[index] = distance_array_sorted_valid[index];
          type_array_sorted[index] = type_array_sorted_valid[index];
        end
      default: 
        read = 1;
    endcase
  end

always @(posedge clk) begin
  if (rst) begin
    for (index = 0; index < L; index = index + 1) begin
      distance_array_sorted_valid[index] = 0; 
      type_array_sorted_valid[index] = 0;
      distance_array_valid[index] = 0;
      data_type_array_valid[index] = 0;
    end 
    state = IDLE;
  end else begin
    case (state)
      IDLE:
        if (start) begin
          state = READ;
        end else begin
          state = IDLE;
        end

      READ:
        if (ready) begin
          state = DIST;
        end else begin
          state = READ;
        end

      DIST:
        state = SORT;

      SORT:
        state = IDLE;
    endcase
  end
end

endmodule
