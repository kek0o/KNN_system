module memory_control #(parameter M, N, W, MAX_ELEMENTS, TYPE_W, L, ADDR_W, BASE_T_ADDR, BASE_I_ADDR)(
  input wire clk,
  input wire rst,
  input wire start,
  input wire data_request,
  input wire done,
  input wire [TYPE_W-1:0] inferred_type,
  input wire inference_done,
  input wire [W-1:0] readdata,
  output reg read,
  output reg [ADDR_W-1:0] readaddress,
  output reg [W-1:0] writedata,
  output reg write,
  output reg [ADDR_W-1:0] writeaddress,
  output reg [W*MAX_ELEMENTS-1:0] input_data,
  output reg [W*MAX_ELEMENTS-1:0] training_data,
  output reg [TYPE_W-1:0] training_data_type,
  output reg read_done,
  output reg idle
);

reg [3:0] state;
reg [W*MAX_ELEMENTS-1:0] training_data_reg;
reg [W*MAX_ELEMENTS-1:0] input_data_reg;
reg [4:0] write_count;
reg latch_type, latch_input, latch_input_done;
reg [ADDR_W-1:0] training_addr;
reg [ADDR_W-1:0] input_addr;
reg [ADDR_W-1:0] inference_addr;
integer i,j, cycle_count_i, cycle_count_t, done_count;
wire [31:0] data_limit;
wire new_request;

assign data_limit = (MAX_ELEMENTS < (M*N)) ? MAX_ELEMENTS : (M*N);
assign new_request = done || data_request;

always @(state) begin
  if (state == 4'd0) idle = 1'b1; // signal used for confirming memory control availability
  else idle = 1'b0;
end

always @(posedge clk)
begin 
  if (rst) begin
    read <= 1'b0;
    write <= 1'b0;
    writedata <= {W{1'b0}};
    read_done <= 1'b0;
    latch_input_done <= 1'b0;
    training_addr <= BASE_T_ADDR;
    input_addr <= BASE_I_ADDR + W;
    inference_addr <= BASE_I_ADDR;
    write_count <= 5'b0;
    cycle_count_i <= 0;
    cycle_count_t <= 0;
    done_count <= 0;
    latch_type <= 1'b1;
    latch_input <= 1'b0;
    training_data_type <= {TYPE_W{1'b0}};
    writeaddress <= BASE_I_ADDR;
    readaddress <= BASE_T_ADDR;
    training_data_reg <= {W*MAX_ELEMENTS{1'b0}};
    input_data_reg <= {W*MAX_ELEMENTS{1'b0}};
    j <= 0;
    state <= 4'd0;
  end else begin
	  case (state)
	  	4'd0: begin // IDLE
	  	  read <= 1'b0;
        read_done <= 1'b0;
        latch_input_done <= 1'b0;
        readaddress <= training_addr;
        write_count <= 5'b0;
        cycle_count_i <= 0;
        cycle_count_t <= 0;
        done_count <= 0;
        latch_type <= 1'b1;
        training_data_reg <= {W*MAX_ELEMENTS{1'b0}};
        input_data_reg <= {W*MAX_ELEMENTS{1'b0}};
        j <= 0;
        state <= start ? 4'd1 : 4'd0;
	  	end
	  	4'd1: begin // read data 
	  		read <= 1'b1;
        if (!write_count[3]) write_count <= write_count + 1'b1;

        if (latch_input) readaddress <= input_addr;
        else readaddress <= training_addr;
        state <= 4'd2;
      end
      4'd2: begin // read activation
        read <= 1'b0;
        state <= 4'd13;
      end
      4'd13: state <= 4'd14; // clk delay
      4'd14: begin // select latch
        if (latch_type) state <= 4'd3;
        else state <= latch_input ? 4'd4 : 4'd5;
      end
      4'd3: begin // latch training type
        training_data_type <= readdata[TYPE_W-1:0];
        training_addr <= training_addr + W;
        latch_type <= 1'b0;
        if (latch_input_done) latch_input <= 1'b0;
        else latch_input <= 1'b1;
        state <= 4'd1;
      end
      4'd4: begin // latch input data
        input_data_reg[W*(j+1)-1-:W] <= readdata;
        input_addr <= input_addr + W; 

        if ((j < data_limit-1) && (cycle_count_i < (M*N-1))) begin
          j <= j + 1;
        end else begin
          j <= 0;
          latch_input <= 1'b0;
        end
        cycle_count_i <= (cycle_count_i == (M*N-1)) ? 0 : cycle_count_i + 1;
        state <= 4'd1;
      end
      4'd5: begin // latch training data
        training_data_reg[W*(j+1)-1-:W] <= readdata;
        training_addr <= training_addr + W;

        if ((j < data_limit-1) && (cycle_count_t < (M*N-1))) begin
          j <= j + 1;
          state <= 4'd1;
        end else begin
          j <= 0;
          state <= 4'd6;
        end
        cycle_count_t <= (cycle_count_t == (M*N-1)) ? 0 : cycle_count_t + 1;
      end
      4'd6: begin // send data
        training_data <= training_data_reg;
        input_data <= input_data_reg;
        read_done <= 1'b1;
        state <= 4'd7;
      end
      4'd7: begin // wait calculation/new_request
        read_done <= 1'b0;
        if (done_count < L-1) begin
          if (new_request) begin
            if (data_request) latch_input <= 1'b1;
            else begin
              done_count <= done_count + 1'b1;
              if (data_limit < (M*N)) input_addr <= inference_addr + W;
              else latch_input_done <= 1'b1;
              latch_type <= 1'b1;
            end
            state <= 4'd1;
          end
        end else begin
          if (new_request) begin
            if (data_request) begin
              latch_input <= 1'b1;
              state <= 4'd1;
            end else begin
              done_count <= 0;
              state <= 4'd8;
            end
          end
        end
      end
      4'd8: begin // wait inference
        latch_input_done <= 1'b0;
        if (inference_done) begin
          writeaddress <= inference_addr;
          writedata <= {{(W-TYPE_W){1'b0}},inferred_type};
          inference_addr <= input_addr; // next inference address
          input_addr <= input_addr + W; // skip input type
          training_addr <= BASE_T_ADDR; // start reading training data again
          state <= 4'd9;
        end
      end
      4'd9: begin // write inferred type
        if (write_count[3]) begin
          write_count <= 5'b0;
          write <= 1'b1;
          state <= 4'd10;
        end else write_count <= write_count + 5'b1;
      end
      4'd10: begin // write activation 
        write <= 1'b0;
        state <= 4'd11;
      end
      4'd11: state <= 4'd12;
      4'd12: state <= 4'd0;
 	    default : state <= 4'd0;
	  endcase
  end
end
endmodule
