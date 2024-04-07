module distance_calculator #(parameter M, N, B)(
  input wire [B-1:0] training_data [0:M-1][0:N-1],
  input wire [B-1:0] input_data [0:M-1][0:N-1],
  output real distance
);

reg [B-1:0] sub, sum;
integer i,j;

always_comb begin
  sum = 0;
  for(i=0; i < M; i=i+1) begin
    for(j=0; j < N; j=j+1) begin
      sub = input_data[i][j] - training_data[i][j];
      sum = sum + sub*sub;
    end 
  end
  distance=$sqrt(sum);
end

endmodule


