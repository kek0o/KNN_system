module distance_calculator #(parameter M, N, W)(
  input wire clk,
  input wire rst,
  input wire ready,
  input wire [W-1:0] training_data [0:(M*N)-1],
  input wire [W-1:0] training_data_type,
  input wire [W-1:0] input_data [0:(M*N)-1],
  output reg [W-1:0] distance,
  output reg [W-1:0] data_type,
  output reg done
);

reg [1:0] state; // 0-IDLE, 1-CALCULATE, 2-DONE

reg [W-1:0] sub, sum;
integer i,j;


always @(posedge clk)
  begin
    if (rst) begin
      distance <= {1'b0 ,{(W-1){1'b1}}}; //max distance possible (signed)
      done <= 0;
      sum <= 0;
      sub <= 0;
      i <= 0;
      j <= 0;

      state <= 2'b00; //IDLE
    end else begin
      case (state)
        2'b00: begin //IDLE
          done <= 0;
          sub <= 0;
          sum <= 0;

          if (ready) begin
            state <= 2'b01; //CALCULATE
          end 
        end
        2'b01: begin //CALCULATE
          if (i < M) begin
            if (j < N) begin
              sub = input_data[i*N + j] - training_data[i*N + j];
              sum = sum + sub*sub;
              j <= j + 1;

            end else begin
              j <= 0;
              i <= i + 1;
            end
          end else begin
            i <= 0;
            state <= 2'b10; //DONE
            done <= 1'b1;
            distance <= sum; //square root avoided for its hardware complexity
          end
        end
        2'b10: begin //DONE
          done <= 1'b0;
          state <= 2'b00; //IDLE
        end
     endcase
    end
  end
  
assign data_type = training_data_type;

endmodule


