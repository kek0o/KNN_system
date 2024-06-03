module knn_test #(parameter M = 6,N = 10,W = 16, MAX_ELEMENTS = 32, TYPE_W = 3, K = 15, L = 6, ADDR_W = 25, BASE_T_ADDR = 0, BASE_I_ADDR = 1<<(ADDR_W-1))(
  input wire clk,
  input wire rst, 
  input wire start_button,
  input wire [W-1:0] readdata,
  output reg read,
  output reg [ADDR_W-1:0] readaddress,
  output reg [W-1:0] writedata,
  output reg write,
  output reg [ADDR_W-1:0] writeaddress,
  output reg idle,
  output reg sdram_write_complete,
  output reg inference_done,
  output reg [TYPE_W-1:0] inferred_type
);

// Memory control signals
reg start, data_request, done;
wire [W-1:0] wr_data_mem_ctrl;
wire wr_mem_ctrl;
wire [ADDR_W-1:0] wr_addr_mem_ctrl;
wire [W*MAX_ELEMENTS-1:0] input_data;
wire [W*MAX_ELEMENTS-1:0] training_data;
wire [TYPE_W-1:0] training_data_type;
wire read_done;
// KNN System signals
wire done_calc;

// Module instances
// Memory Control instance
memory_control #(.M(M),.N(N),.W(W),.MAX_ELEMENTS(MAX_ELEMENTS),.TYPE_W(TYPE_W),.L(1<<L),.ADDR_W(ADDR_W),.BASE_T_ADDR(BASE_T_ADDR),.BASE_I_ADDR(BASE_I_ADDR))
memory_control_inst (
.clk(clk),.rst(rst),.start(start),.data_request(data_request),.done(done),.inferred_type(inferred_type),
.inference_done(inference_done),.readdata(readdata),.read(read),.readaddress(readaddress),.writedata(wr_data_mem_ctrl),
.write(wr_mem_ctrl),.writeaddress(wr_addr_mem_ctrl),.input_data(input_data),.training_data(training_data),
.training_data_type(training_data_type),.read_done(read_done),.idle(idle));

// KNN System instance
knn_system #(.M(M),.N(N),.W(W),.MAX_ELEMENTS(MAX_ELEMENTS),.TYPE_W(TYPE_W),.K(K),.L(L))
knn_system_inst (
.clk(clk),.rst(rst),.read_done(read_done),.training_data(training_data),.training_data_type(training_data_type),
.input_data(input_data),.data_request(data_request),.done(done),.done_calc(done_calc),.inferred_type(inferred_type),
.inference_done(inference_done));

reg [1:0] pre_button;
reg [6:0] lfsr;
reg [6:0] random_value;
reg[ADDR_W-1:0] address;
reg [1:0] state;
reg [4:0] write_count;
integer i,j;

reg wr_sdram;
reg [ADDR_W-1:0] wr_addr_sdram;
reg [W-1:0] wr_data_sdram;

always @(posedge clk)
begin
  if (rst) begin
    sdram_write_complete <= 1'b0;
    pre_button <= 2'b11;
    start <= 1'b0;
    lfsr <= 7'b1;
    random_value <= 7'b0;
    address <= BASE_T_ADDR;
    write_count <= 5'b0;
    i <= 0;
    j <= 0;
    wr_sdram <= 1'b0;
    wr_addr_sdram <= BASE_T_ADDR;
    wr_data_sdram <= 0;
    state <= 2'd0;
  end else begin
    case (state)
      2'b00: begin
        lfsr <= 7'b1;
        random_value <= 7'b0;
        address <= BASE_T_ADDR;
        wr_sdram <= 1'b0;
        i <= 0;
        j <= 0;
        pre_button <= {pre_button[0], start_button};
		    start <= !pre_button[0] && pre_button[1];
        state <= sdram_write_complete ? 2'b00 : 2'b01;
      end
      2'b01: begin
        wr_sdram <= 1'b0;
        if (j == 0) begin
          random_value <= {lfsr[5:0], ~(lfsr[6]^lfsr[4]^lfsr[3]^lfsr[2])} % 100;
          lfsr <= {lfsr[5:0], ~(lfsr[6]^lfsr[4]^lfsr[3]^lfsr[2])};
        end
        wr_addr_sdram <= address;
        state <= 2'b10;
      end
      2'b10: begin
        if (j == 0) begin
          if (i < (1<<L)) begin
            if (random_value < 20) wr_data_sdram <= 1;
            else if (random_value < 40) wr_data_sdram <= 2;
            else if (random_value < 60) wr_data_sdram <= 3;
            else if (random_value < 80) wr_data_sdram <= 4;
            else wr_data_sdram <= 5;
          end else wr_data_sdram <= 0;
          j <= j + 1;
        end else if (j < M*N) begin
          wr_data_sdram <= random_value;
          j <= j + 1;
        end else begin
          j <= 0;
          i <= i + 1;
        end
        if ((i == (1<<L)-1) && (j == M*N)) address <= BASE_I_ADDR;
        else address <= address + W;
        state <= 2'b11;
      end
      2'b11: begin
        if (write_count[3]) begin
          write_count <= 5'b0;
          wr_sdram <= 1'b1;
          if ((i == (1<<L)+10) && (j == M*N)) begin // L training elements + 10 input elements
            sdram_write_complete <= 1'b1;
            state <= 2'b00;
          end else state <= 2'b01;
        end else write_count <= write_count + 1'b1;
      end
    endcase
  end
end
assign writeaddress = !sdram_write_complete ? wr_addr_sdram : wr_addr_mem_ctrl;
assign writedata = !sdram_write_complete ? wr_data_sdram : wr_data_mem_ctrl;
assign write = !sdram_write_complete ? wr_sdram : wr_mem_ctrl;
endmodule
