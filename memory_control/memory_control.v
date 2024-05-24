module memory_control #(parameter M, N, W, MAX_ELEMENTS, ADDR_W, BASE_T_ADDR, BASE_I_ADDR)(
  input wire clk,
  input wire rst,
  input wire start,
  input wire data_request,
  input wire done,
  input wire done_calc,
  input wire [W-1:0] inferred_type,
  input wire inference_done,
  input wire [W-1:0] readdata,
  output reg read,
  output reg [ADDR_W-1:0] readaddress,
  output reg [W-1:0] writedata,
  output reg write,
  output reg [ADDR_W-1:0] writeaddress,
  output reg [W-1:0] input_data [0:(M*N)-1],
  output reg [W-1:0] training_data [0:(M*N)-1],
  output reg [W-1:0] training_data_type,
  output reg read_done
);

reg [3:0] state;
reg [W-1:0] training_data_reg [0:(M*N)-1];
reg [W-1:0] input_data_reg [0:(M*N)-1];
reg [4:0] write_count;
reg latch_type, latch_input, latch_input_done;
reg [ADDR_W-1:0] training_addr;
reg [ADDR_W-1:0] input_addr;
reg [ADDR_W-1:0] inference_addr;
integer i,j, cycle_count_i, cycle_count_t;
reg integer data_limit;
reg new_request;

assign data_limit = (MAX_ELEMENTS < (M*N)) ? MAX_ELEMENTS : (M*N);
assign new_request = done | data_request;

always@(posedge clk)
begin 
  if (rst) begin
    read <= 1'b0;
    write <= 1'b0;
    writedata <= {W{1'b0}};
    read_done <= 1'b0;
    latch_input_done <= 1'b0;
    training_addr <= BASE_T_ADDR;
    input_addr <= BASE_I_ADDR;
    inference_addr <= BASE_I_ADDR;
    write_count <= 5'b0;
    cycle_count_i <= 0;
    cycle_count_t <= 0;
    latch_type <= 1'b1;
    latch_input <= 1'b0;
    training_data_type <= 0;
    writeaddress <= BASE_I_ADDR;
    readaddress <= BASE_T_ADDR;
    for(i = 0; i < (M*N); i = i + 1) begin
      training_data_reg[i] <= {W{1'b0}};
      input_data_reg[i] <= {W{1'b0}};
    end
    j <= 0;
    state <= 4'd0;
  end else begin
	  case (state)
	  	4'd0: begin // IDLE
	  	  read <= 1'b0;
        write <= 1'b0;
        writedata <= {W{1'b0}};
        read_done <= 1'b0;
        latch_input_done <= 1'b0;
        readaddress <= training_addr;
        write_count <= 5'b0;
        cycle_count_i <= 0;
        cycle_count_t <= 0;
        latch_type <= 1'b1;
        for(i = 0; i < (M*N); i = i + 1) begin
          training_data_reg[i] <= {W{1'b0}};
          input_data_reg[i] <= {W{1'b0}};
        end
        j <= 0;
        state <= start ? 4'd1 : 4'd0;
	  	end
	  	4'd1: begin // read data 
	  		read <= 1'b1;
        if (!write_count[3]) write_count <= write_count + 1'b1;
        state <= 4'd2;
      end
      4'd2: begin
        read <= 1'b0;
        if (latch_type) state <= 4'd3;
        else state <= latch_input ? 4'd4 : 4'd5;
      end
      4'd3: begin // latch training type
        training_data_type <= readdata;
        training_addr <= training_addr + W;
        latch_type <= 1'b0;
        if (latch_input_done) readaddress <= training_addr + W;
        else begin
          readaddress <= input_addr + W; // first address (input_addr) is inferred input data type
          latch_input <= 1'b1;
        end
        state <= 4'd1;
      end
      4'd4: begin // latch input data
        input_data_reg[j] <= readdata;
        if ((j < data_limit) && (cycle_count_i < (M*N))) begin
          j <= j + 1;
          readaddress <= readaddress + W;
          input_addr <= input_addr + W;
          cycle_count_i <= cycle_count_i + 1;
        end else begin
          j <= 0;
          latch_input <= 1'b0;
          readaddress <= training_addr;
          input_addr <= input_addr + W;
          if (cycle_count_i == (M*N)) begin
            cycle_count_i <= 0;
            input_addr <= input_addr + 2*W; //skip input type
          end
        end
        state <= 4'd1;
      end
      4'd5: begin // latch training data
        training_data_reg[j] <= readdata;
        training_addr <= training_addr + W;
        if ((j < data_limit) && (cycle_count_t < (M*N))) begin
          j <= j + 1;
          cycle_count_t <= cycle_count_t + 1;
          readaddress <= readaddress + W;
          state <= 4'd1;
        end else begin
          j <= 0;
          if (cycle_count_t == (M*N)) cycle_count_t <= 0;
          state <= 4'd6;
        end
      end
      4'd6: begin // send data
        for (i = 0; i < data_limit; i = i + 1) begin
          training_data[i] <= training_data_reg[i];
          input_data[i] <= input_data_reg[i];
        end
        read_done <= 1'b1;
        state <= 4'd7;
      end
      4'd7: begin // wait calculation
        read_done <= 1'b0;
        if (done_calc) state <= 4'd8;
        else begin
          if (new_request) begin
            if (done) begin
              if (data_limit < (M*N)) begin
                latch_input <= 1'b1;
                readaddress <= input_addr;
              end else begin
                latch_type <= 1'b1;
                latch_input_done <= 1'b1;
              end
            end else begin // data request
              latch_input <= 1'b1;
              readaddress <= input_addr;
            end
            state <= 4'd1;
          end else state <= 4'd7;
        end
      end
      4'd8: begin // wait inference
        latch_input_done <= 1'b0;
        if (inference_done) begin
          writeaddress <= inference_addr;
          writedata <= inferred_type;
          inference_addr <= input_addr; // next inference address
          state <= 4'd9;
        end else state <= 4'd8;
      end
      4'd9: begin // write inferred type
        if (write_count[3]) begin
          write_count <= 5'b0;
          write <= 1'b1;
          state <= 4'd10;
        end else write_count <= write_count + 5'b1;
      end
      4'd10: begin 
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
