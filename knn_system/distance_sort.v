module distance_sort #(parameter N, W)(
  input wire clk,
  input wire rst,
  input wire done,
  input wire [W-1:0] distance_array[0:N-1], 
  input wire [W-1:0] type_array[0:N-1],
  output reg [W-1:0] distance_array_sorted[0:N-1],
  output reg [W-1:0] type_array_sorted[0:N-1],
  output reg valid_sort
);

genvar i_gen, j_gen;

reg [W-1:0] distance_array_sorted_temp[0:N-1];
reg [W-1:0] type_array_sorted_temp[0:N-1];

reg [W-1:0] temp_array[0:N*(N+1)-1];
reg [W-1:0] type_temp_array[0:N*(N+1)-1];

generate
  for(i_gen = 0; i_gen < N; i_gen = i_gen + 1) begin
    if (i_gen[0] == 1'b0) begin //even elements
      for( j_gen = 0; j_gen < N; j_gen = j_gen + 2)
        sort_2 sort_2_inst (.A(temp_array[i_gen*N+j_gen]), .B(temp_array[i_gen*N+j_gen+1]),.A_type(type_temp_array[i_gen*N+j_gen]), .B_type(type_temp_array[i_gen*N+j_gen+1]),
      .H(temp_array[i_gen*N+j_gen+N]), .L(temp_array[i_gen*N+j_gen+N+1]), .H_type(type_temp_array[i_gen*N+j_gen+N]), .L_type(type_temp_array[i_gen*N+j_gen+N+1]));
    end
    else begin
      assign temp_array[i_gen*N+N] = temp_array[i_gen*N];
      assign type_temp_array[i_gen*N+N] = type_temp_array[i_gen*N];

      for (j_gen = 1; j_gen < N - 2; j_gen = j_gen + 2)
        sort_2 sort_2_inst (.A(temp_array[i_gen*N+j_gen]), .B(temp_array[i_gen*N+j_gen+1]), .A_type(type_temp_array[i_gen*N+j_gen]), .B_type(type_temp_array[i_gen*N+j_gen+1]),
      .H(temp_array[i_gen*N+j_gen+N]), .L(temp_array[i_gen*N+j_gen+N+1]), .H_type(type_temp_array[i_gen*N+j_gen+N]), .L_type(type_temp_array[i_gen*N+j_gen+N+1]));

        assign temp_array[i_gen*N+(N-1)+N] = temp_array[i_gen*N+(N-1)];
        assign type_temp_array[i_gen*N+(N-1)+N] = type_temp_array[i_gen*N+(N-1)];

    end
  end

  for(i_gen = 0; i_gen < N; i_gen = i_gen + 1) begin
    assign temp_array[i_gen] = distance_array[i_gen];
    assign type_temp_array[i_gen] = type_array[i_gen];

    assign distance_array_sorted_temp[i_gen] = temp_array[N*N+i_gen];
    assign type_array_sorted_temp[i_gen] = type_temp_array[N*N+i_gen];

  end
endgenerate

integer k_int;

always @(posedge clk)
  begin
    if (rst) begin
      valid_sort <= 0;
      for (k_int = 0; k_int < N; k_int = k_int + 1) begin
        distance_array_sorted[k_int] = 0;
        type_array_sorted[k_int] = 0;
      end
    end else begin
      if (done) begin
        for (k_int = 0; k_int < N; k_int = k_int + 1) begin
          distance_array_sorted[k_int] <= distance_array_sorted_temp[k_int]; //valid sorted array when correct data on input (done)
          type_array_sorted[k_int] <= type_array_sorted_temp[k_int]; //valid type array when correct data on input (done)
        end
        valid_sort <= 1;
      end else begin
        valid_sort <= 0;
      end
    end
  end

endmodule

