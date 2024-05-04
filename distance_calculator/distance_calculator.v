module distance_calculator #(parameter M, N, W)(
  input wire clk,
  input wire rst,
  input wire ready,
  input wire [W-1:0] training_data [0:M-1][0:N-1],
  input wire [W-1:0] training_data_type,
  input wire [W-1:0] input_data [0:M-1][0:N-1],
  output reg [W-1:0] distance,
  output reg [W-1:0] data_type,
  output reg done
);

parameter IDLE = 0, CALCULATE = 1, DONE = 2;
reg [1:0] state;

reg [W-1:0] sub, sum;
integer i,j;


always @(posedge clk)
  begin
    if (rst) begin
      distance <= {W{1'b1}}; //max distance possible
      done <= 0;
      sum <= 0;
      sub <= 0;
      i <= 0;
      j <= 0;

      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          done <= 0;
          sub <= 0;
          sum <= 0;

          if (ready) begin
            state = CALCULATE;
          end 
        end
        CALCULATE: begin
          //colums calculation stage
          if (i < M) begin
            for (j = 0; j < N; j = j + 1) begin
              sub = input_data[i][j] - training_data[i][j];
              sum = sum + sub*sub;
            end
            i <= i + 1; //rows calculation stage

          end else begin
            i <= 0;

            state <= DONE;
            done <= 1;
            distance <= sum; //square root avoided for its hardware complexity
          end
        end
        DONE: begin
          done <= 0;
          state <= IDLE;
        end
     endcase
    end
  end
  
assign data_type = training_data_type;

endmodule


