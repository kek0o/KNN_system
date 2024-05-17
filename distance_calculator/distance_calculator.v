module distance_calculator #(parameter M, N, W, MAX_ELEMENTS, TYPE_W)(
  input wire clk,
  input wire rst,
  input wire ready,
  input wire [W-1:0] training_data [0:(M*N)-1],
  input wire [TYPE_W-1:0] training_data_type,
  input wire [W-1:0] input_data [0:(M*N)-1],
  output reg [W-1:0] distance,
  output reg [TYPE_W-1:0] data_type,
  output reg done,
  output reg data_request
);

reg [1:0] state; // 0-IDLE, 1-CALCULATE, 2-DONE, 3-REQUEST_DATA

reg [W-1:0] sub, sum;
integer i, cycle_count;


always @(posedge clk)
  begin
    if (rst) begin
      distance <= {1'b0 ,{(W-1){1'b1}}}; //max distance possible (signed)
      done <= 1'b0;
      data_request <= 1'b0;
      sum <= 0;
      sub <= 0;
      i <= 0;
      cycle_count <= 0;
      state <= 2'b00; //IDLE
    end else begin
      case (state)
        2'b00: begin //IDLE
          done <= 1'b0;
          sub <= 0;
          sum <= 0;

          if (ready) begin
            state <= 2'b01; //CALCULATE
          end 
        end
        2'b01: begin //CALCULATE
          if ((i < (M*N)) && (i < MAX_ELEMENTS) && (cycle_count < (M*N))) begin
            sub = input_data[i] - training_data[i];
            sum = sum + sub*sub;
            i <= i + 1;
            cycle_count <= cycle_count + 1;
          end else begin
            i <= 0;
            if ((MAX_ELEMENTS < (M*N)) && (cycle_count < (M*N))) begin
              data_request <= 1'b1; //request remaining data
              state <= 2'b11; //REQUEST_DATA
            end else begin
              cycle_count <= 0;
              done <= 1'b1;
              distance <= sum; //square root avoided for its hardware complexity
              state <= 2'b10; //DONE
            end
          end
        end 
        2'b10: begin //DONE
          done <= 1'b0;
          state <= 2'b00; //IDLE
        end
        2'b11: begin //REQUEST_DATA
          data_request <= 1'b0;
          if (ready) begin
            state <= 2'b01; //CALCULATE
          end
        end

     endcase
    end
  end
  
assign data_type = training_data_type;

endmodule


