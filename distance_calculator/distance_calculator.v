<<<<<<< HEAD
module distance_calculator #(parameter M, N, W)(
=======
module distance_calculator #(parameter M, N, W, MAX_ELEMENTS, TYPE_W)(
>>>>>>> knn_system
  input wire clk,
  input wire rst,
  input wire ready,
<<<<<<< HEAD
  input wire [W-1:0] training_data [0:(M*N)-1],
<<<<<<< HEAD
  input wire [W-1:0] training_data_type,
  input wire [W-1:0] input_data [0:(M*N)-1],
  output reg [W-1:0] distance,
  output reg [W-1:0] data_type,
  output reg done
);

reg [1:0] state; // 0-IDLE, 1-CALCULATE, 2-DONE

reg [W-1:0] sub, sum;
integer i,j;

=======
=======
  input wire [W*MAX_ELEMENTS-1:0] training_data,
>>>>>>> packed_implementation
  input wire [TYPE_W-1:0] training_data_type,
  input wire [W*MAX_ELEMENTS-1:0] input_data,
  output reg [2*W-1:0] distance,
  output reg [TYPE_W-1:0] data_type,
  output reg done,
  output reg data_request
);

reg [2:0] state; // 0-IDLE, 1-CALCULATE, 2-SUM, 3-DONE, 4-REQUEST_DATA

reg [2*W-1:0] sub, sum;
integer i, cycle_count;

<<<<<<< HEAD
>>>>>>> knn_system

always @(posedge clk)
  begin
    if (rst) begin
      distance <= {1'b0 ,{(W-1){1'b1}}}; //max distance possible (signed)
<<<<<<< HEAD
      done <= 0;
      sum <= 0;
      sub <= 0;
      i <= 0;
      j <= 0;

=======
      done <= 1'b0;
      data_request <= 1'b0;
      sum <= 0;
      sub <= 0;
      i <= 0;
      cycle_count <= 0;
>>>>>>> knn_system
      state <= 2'b00; //IDLE
    end else begin
      case (state)
        2'b00: begin //IDLE
<<<<<<< HEAD
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
=======
          done <= 1'b0;
          sub <= 0;
          sum <= 0;
          state <= ready ? 2'b01 : 2'b00;
        end
        2'b01: begin //CALCULATE
          if ((i < MAX_ELEMENTS) && (cycle_count < (M*N))) begin
            sub = input_data[i] - training_data[i];
            sum = sum + sub*sub;
            i <= i + 1;
            cycle_count <= cycle_count + 1;
=======
always @(posedge clk) begin
  if (rst) begin
    distance <= {1'b0, {(2*W-1){1'b1}}}; //max distance possible (signed)
    done <= 1'b0;
    data_request <= 1'b0;
    sum <= 0;
    sub <= 0;
    i <= 0;
    cycle_count <= 0;
    data_type <= {TYPE_W{1'b0}};
    state <= 2'b00; //IDLE
  end else begin
    case (state)
      3'b000: begin //IDLE
        done <= 1'b0;
        sub <= 0;
        sum <= 0;
        state <= ready ? 3'b001 : 3'b000;
      end
      3'b001: begin //CALCULATE
        if ((i < MAX_ELEMENTS) && (cycle_count < (M*N))) begin
          sub <= input_data[(i+1)*W-1 -: W] - training_data[(i+1)*W-1 -: W];
          i <= i + 1;
          cycle_count <= cycle_count + 1;
          state <= 3'b010;
        end else begin
          i <= 0;
          if (cycle_count < (M*N)) begin
            data_request <= 1'b1; //request remaining data
            state <= 3'b100; //REQUEST_DATA
>>>>>>> packed_implementation
          end else begin
            cycle_count <= 0;
	          data_type <= training_data_type;
            state <= 3'b011; //DONE
          end
<<<<<<< HEAD
        end 
>>>>>>> knn_system
        2'b10: begin //DONE
          done <= 1'b0;
          state <= 2'b00; //IDLE
        end
<<<<<<< HEAD
=======
        2'b11: begin //REQUEST_DATA
          data_request <= 1'b0;
          state <= ready ? 2'b01 : 2'b11;
        end
>>>>>>> knn_system
     endcase
    end
=======
        end
      end 
      3'b010: begin // SUM
        sum <= sum + sub*sub;
        state <= 3'b001;
      end
      3'b011: begin //DONE
        done <= 1'b1;
        distance <= sum; //square root avoided for its hardware complexity
        state <= 3'b000; //IDLE
      end
      3'b100: begin //REQUEST_DATA
        data_request <= 1'b0;
        state <= ready ? 3'b001 : 3'b100;
      end
    endcase
>>>>>>> packed_implementation
  end
end

endmodule

