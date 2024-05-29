module distance_sort #(parameter N, W, TYPE_W)(
  input wire clk,
  input wire rst,
  input wire done,
  input wire [W*N-1:0] distance_array,
  input wire [TYPE_W*N-1:0] type_array,
  output reg [W*N-1:0] distance_array_sorted,
  output reg [TYPE_W*N-1:0] type_array_sorted,
  output reg valid_sort
);

  genvar i, j;
  reg [1:0] state;

  reg [W*N-1:0] distance_array_sorted_temp;
  reg [TYPE_W*N-1:0] type_array_sorted_temp;
  reg [W*2*N-1:0] distance_array_sorted_sync;
  reg [TYPE_W*2*N-1:0] type_array_sorted_sync;

  wire [W*N*(N+1)-1:0] temp_array;
  wire [TYPE_W*N*(N+1)-1:0] type_temp_array;

  generate
    for (i = 0; i < N; i = i + 1) begin : sorting_network
      if (i[0] == 1'b0) begin //even elements
        for (j = 0; j < N; j = j + 2) begin : even_numbers_sorting_network
          sort_2 #(.W(W), .TYPE_W(TYPE_W)) sort_2_inst (
            .A(temp_array[(i*N+j+1)*W-1 -: W]), 
            .B(temp_array[(i*N+j+2)*W-1 -: W]),
            .A_type(type_temp_array[(i*N+j+1)*TYPE_W-1 -: TYPE_W]), 
            .B_type(type_temp_array[(i*N+j+2)*TYPE_W-1 -: TYPE_W]),
            .H(temp_array[(i*N+j+N+1)*W-1 -: W]), 
            .L(temp_array[(i*N+j+N+2)*W-1 -: W]), 
            .H_type(type_temp_array[(i*N+j+N+1)*TYPE_W-1 -: TYPE_W]), 
            .L_type(type_temp_array[(i*N+j+N+2)*TYPE_W-1 -: TYPE_W])
          );
        end
      end else begin
        assign temp_array[(i*N+N+1)*W-1 -: W] = temp_array[(i*N+1)*W-1 -: W];
        assign type_temp_array[(i*N+N+1)*TYPE_W-1 -: TYPE_W] = type_temp_array[(i*N+1)*TYPE_W-1 -: TYPE_W];

        for (j = 1; j < N - 2; j = j + 2) begin : odd_numbers_sorting_network
          sort_2 #(.W(W), .TYPE_W(TYPE_W)) sort_2_inst (
            .A(temp_array[(i*N+j+1)*W-1 -: W]), 
            .B(temp_array[(i*N+j+2)*W-1 -: W]),
            .A_type(type_temp_array[(i*N+j+1)*TYPE_W-1 -: TYPE_W]), 
            .B_type(type_temp_array[(i*N+j+2)*TYPE_W-1 -: TYPE_W]),
            .H(temp_array[(i*N+j+N+1)*W-1 -: W]), 
            .L(temp_array[(i*N+j+N+2)*W-1 -: W]), 
            .H_type(type_temp_array[(i*N+j+N+1)*TYPE_W-1 -: TYPE_W]), 
            .L_type(type_temp_array[(i*N+j+N+2)*TYPE_W-1 -: TYPE_W])
          );
        end

        assign temp_array[(i*N+N-1+N+1)*W-1 -: W] = temp_array[(i*N+N-1+1)*W-1 -: W];
        assign type_temp_array[(i*N+N-1+N+1)*TYPE_W-1 -: TYPE_W] = type_temp_array[(i*N+N-1+1)*TYPE_W-1 -: TYPE_W];
      end
    end

    for (i = 0; i < N; i = i + 1) begin : array_assignation
      assign temp_array[(i+1)*W-1 -: W] = distance_array[(i+1)*W-1 -: W];
      assign type_temp_array[(i+1)*TYPE_W-1 -: TYPE_W] = type_array[(i+1)*TYPE_W-1 -: TYPE_W];

      assign distance_array_sorted_temp[(i+1)*W-1 -: W] = temp_array[(N*N+i+1)*W-1 -: W];
      assign type_array_sorted_temp[(i+1)*TYPE_W-1 -: TYPE_W] = type_temp_array[(N*N+i+1)*TYPE_W-1 -: TYPE_W];
    end
  endgenerate

  always @(posedge clk) begin
    if (rst) begin
      valid_sort <= 1'b0;
      distance_array_sorted_sync <= {2*N*W{1'b0}};
      type_array_sorted_sync <= {2*N*TYPE_W{1'b0}};
      state <= 2'b00;
    end else begin
      case (state)
        2'b00: begin // SORTING
          valid_sort <= 1'b0;
          distance_array_sorted_sync <= {2*N*W{1'b0}};
          type_array_sorted_sync <= {2*N*TYPE_W{1'b0}};
          state <= done ? 2'b01 : 2'b00;
        end
        2'b01: begin // SYNC_SORT
          distance_array_sorted_sync <= {distance_array_sorted_sync[W*N-1:0], distance_array_sorted_temp}; 
          type_array_sorted_sync <= {type_array_sorted_sync[TYPE_W*N-1:0], type_array_sorted_temp}; 
          state <= 2'b10;
        end
        2'b10: begin // VALIDATING_SORT
          if (distance_array_sorted_sync[W*N-1:0] != distance_array_sorted_sync[2*W*N-1:W*N]) 
            state <= 2'b01;
          else 
            state <= 2'b11;
        end
        2'b11: begin // VALID_SORT
          distance_array_sorted <= distance_array_sorted_sync[W*N-1:0]; 
          type_array_sorted <= type_array_sorted_sync[TYPE_W*N-1:0]; 
          valid_sort <= 1'b1;
          state <= 2'b00;
        end
      endcase
    end
  end
endmodule

