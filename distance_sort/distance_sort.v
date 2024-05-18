<<<<<<< HEAD
module distance_sort #(parameter N, W)(
=======
module distance_sort #(parameter N, W, TYPE_W)(
>>>>>>> knn_system
  input wire clk,
  input wire rst,
  input wire done,
  input wire [W-1:0] distance_array[0:N-1], 
  input wire [TYPE_W-1:0] type_array[0:N-1],
  output reg [W-1:0] distance_array_sorted[0:N-1],
<<<<<<< HEAD
  output reg [W-1:0] type_array_sorted[0:N-1],
=======
  output reg [TYPE_W-1:0] type_array_sorted[0:N-1],
>>>>>>> knn_system
  output reg valid_sort
);

genvar i, j;
reg [1:0] state;

reg [W-1:0] distance_array_sorted_temp[0:N-1];
reg [TYPE_W-1:0] type_array_sorted_temp[0:N-1];
reg [W-1:0] distance_array_sorted_sync[0:2*N-1];
reg [TYPE_W:0] type_array_sorted_sync[0:2*N-1];


reg [W-1:0] distance_array_sorted_temp[0:N-1];
reg [W-1:0] type_array_sorted_temp[0:N-1];

reg [W-1:0] temp_array[0:N*(N+1)-1];
reg [TYPE_W-1:0] type_temp_array[0:N*(N+1)-1];

generate
  for(i = 0; i < N; i = i + 1) begin
    if (i[0] == 1'b0) begin //even elements
      for( j = 0; j < N; j = j + 2)
        sort_2 #(W, TYPE_W) sort_2_inst (.A(temp_array[i*N+j]), .B(temp_array[i*N+j+1]),.A_type(type_temp_array[i*N+j]), .B_type(type_temp_array[i*N+j+1]),
      .H(temp_array[i*N+j+N]), .L(temp_array[i*N+j+N+1]), .H_type(type_temp_array[i*N+j+N]), .L_type(type_temp_array[i*N+j+N+1]));
    end
    else begin
      assign temp_array[i*N+N] = temp_array[i*N];
      assign type_temp_array[i*N+N] = type_temp_array[i*N];

      for (j = 1; j < N - 2; j = j + 2)
        sort_2 #(W, TYPE_W) sort_2_inst (.A(temp_array[i*N+j]), .B(temp_array[i*N+j+1]), .A_type(type_temp_array[i*N+j]), .B_type(type_temp_array[i*N+j+1]),
      .H(temp_array[i*N+j+N]), .L(temp_array[i*N+j+N+1]), .H_type(type_temp_array[i*N+j+N]), .L_type(type_temp_array[i*N+j+N+1]));

        assign temp_array[i*N+(N-1)+N] = temp_array[i*N+(N-1)];
        assign type_temp_array[i*N+(N-1)+N] = type_temp_array[i*N+(N-1)];

    end
  end

  for(i = 0; i < N; i = i + 1) begin
    assign temp_array[i] = distance_array[i];
    assign type_temp_array[i] = type_array[i];

    assign distance_array_sorted_temp[i] = temp_array[N*N+i];
    assign type_array_sorted_temp[i] = type_temp_array[N*N+i];

  end
endgenerate

integer k;
<<<<<<< HEAD
=======
reg stability_error;
>>>>>>> knn_system

always @(posedge clk)
  begin
    if (rst) begin
<<<<<<< HEAD
      valid_sort <= 0;
      for (k = 0; k < N; k = k + 1) begin
        distance_array_sorted[k] = 0;
        type_array_sorted[k] = 0;
      end
    end else begin
      if (done) begin
        for (k = 0; k < N; k = k + 1) begin
          distance_array_sorted[k] <= distance_array_sorted_temp[k]; //valid sorted array when correct data on input (done)
          type_array_sorted[k] <= type_array_sorted_temp[k]; //valid type array when correct data on input (done)
        end
        valid_sort <= 1;
      end else begin
        valid_sort <= 0;
      end
    end
  end

=======
      valid_sort <= 1'b0;
      stability_error <= 1'b0;
      for (k = 0; k < N; k = k + 1) begin
        distance_array_sorted_sync[k] = {W{1'b0}};
        type_array_sorted_sync[k] = {TYPE_W{1'b0}};
      end
      state <= 2'b00;
    end else begin
      case (state)
        2'b00: begin // SORTING
          valid_sort <= 1'b0;
          stability_error <= 1'b0;
          for (k = 0; k < N; k = k + 1) begin
            distance_array_sorted_sync[k] = {W{1'b0}};
            type_array_sorted_sync[k] = {TYPE_W{1'b0}};
          end
          state <= done ? 2'b01 : 2'b00;
        end
        2'b01: begin // SYNC_SORT
          stability_error <= 1'b0;
          for (k = 0; k < N; k = k + 1) begin
            distance_array_sorted_sync[k] <= distance_array_sorted_temp[k]; 
            distance_array_sorted_sync[N + k] <= distance_array_sorted_sync[k]; 

            type_array_sorted_sync[k] <= type_array_sorted_temp[k];
            type_array_sorted_sync[N + k] <= type_array_sorted_sync[k];
          end
        state <= 2'b10;
        end
        2'b10: begin // VALIDATING_SORT
          for (k = 0; k < N; k = k + 1) 
            if(distance_array_sorted_sync[k] != distance_array_sorted_sync[N + k]) stability_error = 1'b1;
          state <= stability_error ? 2'b01 : 2'b11;
        end
        2'b11: begin // VALID_SORT
          for (k = 0; k < N; k = k + 1) begin
            distance_array_sorted[k] <= distance_array_sorted_sync[k]; 
            type_array_sorted[k] <= type_array_sorted_sync[k]; 
          end
          valid_sort <= 1'b1;
          state <= 2'b00;
        end
      endcase
    end
  end
>>>>>>> knn_system
endmodule

