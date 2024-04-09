module distance_sort #(parameter N, W)(
  input wire [W-1:0] distance_array[0:N-1], 
  input wire [W-1:0] type_array[0:N-1],
  output reg [W-1:0] distance_array_sorted[0:N-1],
  output reg [W-1:0] type_array_sorted[0:N-1]
);

genvar i, j;

reg [W-1:0] temp_array[0:N*(N+1)-1];
reg [W-1:0] type_temp_array[0:N*(N+1)-1];

generate
  for(i = 0; i < N; i = i + 1) begin
    if (i[0] == 1'b0) begin //even elements
      for( j = 0; j < N; j = j + 2)
        sort_2 sort_2_inst (.A(temp_array[i*N+j]), .B(temp_array[i*N+j+1]),.A_type(type_temp_array[i*N+j]), .B_type(type_temp_array[i*N+j+1]),
      .H(temp_array[i*N+j+N]), .L(temp_array[i*N+j+N+1]), .H_type(type_temp_array[i*N+j+N]), .L_type(type_temp_array[i*N+j+N+1]));
    end
    else begin
      assign temp_array[i*N+N] = temp_array[i*N];
      assign type_temp_array[i*N+N] = type_temp_array[i*N];

      for (j = 1; j < N - 2; j = j + 2)
        sort_2 sort_2_inst (.A(temp_array[i*N+j]), .B(temp_array[i*N+j+1]), .A_type(type_temp_array[i*N+j]), .B_type(type_temp_array[i*N+j+1]),
      .H(temp_array[i*N+j+N]), .L(temp_array[i*N+j+N+1]), .H_type(type_temp_array[i*N+j+N]), .L_type(type_temp_array[i*N+j+N+1]));

        assign temp_array[i*N+(N-1)+N] = temp_array[i*N+(N-1)];
        assign type_temp_array[i*N+(N-1)+N] = type_temp_array[i*N+(N-1)];

    end
  end

  for(i = 0; i < N; i = i + 1) begin
    assign temp_array[i] = distance_array[i];
    assign type_temp_array[i] = type_array[i];

    assign distance_array_sorted[i] = temp_array[N*N+i];
    assign type_array_sorted[i] = type_temp_array[N*N+i];

  end
endgenerate

endmodule

