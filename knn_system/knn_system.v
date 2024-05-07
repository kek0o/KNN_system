module knn_system #(parameter M, N, W, K, L)(
  input wire clk,
  input wire rst,
  input wire start,
  input wire read_done,
  input wire write_done,
  input wire [W-1:0] training_data [0:L-1][0:M-1][0:N-1],
  input wire [W-1:0] training_data_type [0:L-1],
  input wire [W-1:0] input_data [0:M-1][0:N-1],
  output reg [W-1:0] distance_array_sorted [0:L-1],
  output reg [W-1:0] type_array_sorted [0:L-1],
  output reg read,
  output reg write
);

parameter READ = 1, DIST = 2, SORT = 3, WRITE = 4;

genvar k_gen;

wire [W-1:0] distance_array [0:L-1];
wire [W-1:0] data_type_array [0:L-1];

reg done [0:L-1];
reg done_calc;
reg valid_sort;
reg [W-1:0] done_count;

reg [2:0] state_knn;

generate 
  for (k_gen = 0; k_gen < L; k_gen = k_gen + 1) begin
    distance_calculator #(M,N,W) distance_calculator_inst (.clk(clk), .rst(rst), .ready(read_done), .training_data(training_data[k_gen]), 
      .training_data_type(training_data_type[k_gen]), .input_data(input_data), .distance(distance_array[k_gen]), .data_type(data_type_array[k_gen]), .done(done[k_gen]));
  end

distance_sort #(N,W) distance_sort_inst (.clk(clk), .rst(rst), .done(done_calc), .distance_array(distance_array), .type_array(type_array), 
  .distance_array_sorted(distance_array_sorted), .type_array_sorted(type_array_sorted), .valid_sort(valid_sort));

integer m;

always @(state_knn) begin
  if (state_knn == DIST) begin
    for (j = 0; j < L; j = j + 1) begin 
      if (done[j] == 1'b1) done_count = done_count + 1;
    end
    if (done_count == L) begin
      done_calc = 1'b1;
      done_count = 0;
    end
  end else done_count = 0;
end

always @(posedge clk) begin
  if (rst) begin
    for (m = 0; m < L; m = m + 1) begin
      distance_array[m] <= {W{1'b1}};
      data_type_array[m] <= 1'b0;
      done[m] <= 1'b0;
    end
    done_calc <= 1'b0;
    valid_sort <= 1'b0;

    state_knn <= IDLE;
  end else begin
    case (state_knn)
      IDLE: begin
        if (start) begin
          read <= 1'b1;
          state_knn <= READ;
        end else begin
          state_knn <= IDLE;
        end
      end
      READ: begin
        if (read_done) begin
          read <= 1'b0;
          state_knn <= DIST;
        end else begin
          state_knn <= IDLE;
        end
      end
      DIST: begin
        if (done_calc) begin
          state_knn <= SORT;
        end else begin
          state_knn <= DIST;
        end
      end
      SORT: begin
        if (valid_sort) begin
          state_knn <= WRITE;
        end else begin 
          state_knn <= SORT;
        end
      end
      WRITE: begin
        if (write_done) begin
          state_knn <= IDLE;
        end else begin
          state_knn <= WRITE;
        end
      end
    endcase
  end
end

endmodule
