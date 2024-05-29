module distance_sort #(parameter N = 4, parameter W = 8, parameter TYPE_W = 4)(
  input wire clk,
  input wire rst,
  input wire done,
  input wire [N*W-1:0] distance_array, 
  input wire [N*TYPE_W-1:0] type_array,
  output reg [N*W-1:0] distance_array_sorted,
  output reg [N*TYPE_W-1:0] type_array_sorted,
  output reg valid_sort
);

genvar i, j;
reg [1:0] state;

reg [N*W-1:0] distance_array_sorted_temp;
reg [N*TYPE_W-1:0] type_array_sorted_temp;
reg [2*N*W-1:0] distance_array_sorted_sync;
reg [2*N*TYPE_W-1:0] type_array_sorted_sync;

wire [N*(N+1)*W-1:0] temp_array;
wire [N*(N+1)*TYPE_W-1:0] type_temp_array;

generate
  for(i = 0; i < N; i = i + 1) begin
    if (i[0] == 1'b0) begin // even elements
      for(j = 0; j < N; j = j + 2) begin
        sort_2 #(W, TYPE_W) sort_2_inst (
          .A(temp_array[(i*N+j)*W +: W]), 
          .B(temp_array[(i*N+j+1)*W +: W]),
          .A_type(type_temp_array[(i*N+j)*TYPE_W +: TYPE_W]), 
          .B_type(type_temp_array[(i*N+j+1)*TYPE_W +: TYPE_W]),
          .H(temp_array[(i*N+j+N)*W +: W]), 
          .L(temp_array[(i*N+j+N+1)*W +: W]),
          .H_type(type_temp_array[(i*N+j+N)*TYPE_W +: TYPE_W]), 
          .L_type(type_temp_array[(i*N+j+N+1)*TYPE_W +: TYPE_W])
        );
      end
    end else begin
      assign temp_array[(i*N+N)*W +: W] = temp_array[(i*N)*W +: W];
      assign type_temp_array[(i*N+N)*TYPE_W +: TYPE_W] = type_temp_array[(i*N)*TYPE_W +: TYPE_W];

      for(j = 1; j < N-2; j = j + 2) begin
        sort_2 #(W, TYPE_W) sort_2_inst (
          .A(temp_array[(i*N+j)*W +: W]), 
          .B(temp_array[(i*N+j+1)*W +: W]),
          .A_type(type_temp_array[(i*N+j)*TYPE_W +: TYPE_W]), 
          .B_type(type_temp_array[(i*N+j+1)*TYPE_W +: TYPE_W]),
          .H(temp_array[(i*N+j+N)*W +: W]), 
          .L(temp_array[(i*N+j+N+1)*W +: W]),
          .H_type(type_temp_array[(i*N+j+N)*TYPE_W +: TYPE_W]), 
          .L_type(type_temp_array[(i*N+j+N+1)*TYPE_W +: TYPE_W])
        );
      end

      assign temp_array[(i*N+(N-1)+N)*W +: W] = temp_array[(i*N+(N-1))*W +: W];
      assign type_temp_array[(i*N+(N-1)+N)*TYPE_W +: TYPE_W] = type_temp_array[(i*N+(N-1))*TYPE_W +: TYPE_W];
    end
  end

  for(i = 0; i < N; i = i + 1) begin
    assign temp_array[i*W +: W] = distance_array[i*W +: W];
    assign type_temp_array[i*TYPE_W +: TYPE_W] = type_array[i*TYPE_W +: TYPE_W];

    assign distance_array_sorted_temp[i*W +: W] = temp_array[(N*N+i)*W +: W];
    assign type_array_sorted_temp[i*TYPE_W +: TYPE_W] = type_temp_array[(N*N+i)*TYPE_W +: TYPE_W];
  end
endgenerate

integer k;
reg stability_error;

always @(posedge clk) begin
  if (rst) begin
    valid_sort <= 1'b0;
    stability_error <= 1'b0;
    distance_array_sorted_sync <= {(2*N*W){1'b0}};
    type_array_sorted_sync <= {(2*N*TYPE_W){1'b0}};
    state <= 2'b00;
  end else begin
    case (state)
      2'b00: begin // SORTING
        valid_sort <= 1'b0;
        stability_error <= 1'b0;
        distance_array_sorted_sync <= {(2*N*W){1'b0}};
        type_array_sorted_sync <= {(2*N*TYPE_W){1'b0}};
        state <= done ? 2'b01 : 2'b00;
      end
      2'b01: begin // SYNC_SORT
        stability_error <= 1'b0;
        distance_array_sorted_sync <= {distance_array_sorted_sync[W*N-1:0],distance_array_sorted_temp};
        type_array_sorted_sync <= {type_array_sorted_sync[W*N-1:0],type_array_sorted_temp};

        state <= 2'b10;
      end
      2'b10: begin // VALIDATING_SORT
        stability_error <= (distance_array_sorted_sync[N*W-1:0] != distance_array_sorted_sync[2*N*W-1:N*W]);
        state <= stability_error ? 2'b01 : 2'b11;
      end
      2'b11: begin // VALID_SORT
        distance_array_sorted <= distance_array_sorted_sync[N*W-1:0]; 
        type_array_sorted <= type_array_sorted_sync[N*TYPE_W-1:0]; 

        valid_sort <= 1'b1;
        state <= 2'b00;
      end
    endcase
  end
end
endmodule

