module memory_control(
  input wire clk,
  input wire rst,
  input wire start,
  input wire data_request,
  input wire [TYPE_W-1:0] input_data_type,
  input wire inference_done;
  input wire [W-1:0] readdata,
  output reg read,
  output reg [ADDRESS_W-1:0] readaddress,
  output reg [W-1:0] writedata,
  output reg write,
  output reg [ADDRESS_W-1:0] writeaddress,
  output reg [W-1:0] input_data [0:(M*N)-1],
  output reg [W-1:0] training_data [0:(M*N)-1],
  output reg data_ready
);

reg [1:0] state; // 0-IDLE, 1-WRITE, 2-READ, 3-DONE
reg [W-1:0] training_data_reg [0:(M*N)-1];
integer i,j;

always@(posedge clk)
begin
  if (rst) begin
    read <= 1'b0;
    write <= 1'b0;
    data_ready <= 1'b0;
    writedata <= {W{1'b0}};
    state <= 2'b00; // IDLE
  end else begin
  case (state)
    2'b00: begin // IDLE
      read <= 1'b0;
      write <= 1'b0;
      data_ready <= 1'b0;
      state <= (start || inference_done) ? 2'b01 : 2'b00;
    end
    2'b01: begin //WRITE
    if (write_count[3]) begin
      write_count <= 5'b0;
      write <= 1'b1;
      if (start) writedata <= test_data;
      end else writedata <= reg_input_data[i];

      writeaddress <= writeaddres + W;//????
      i <= i + 1;
    end else write_count <= write_count + 1'b1;
    end
    2'b10: begin //READ
      read <= 1'b1;
      if (!write_count[3]) write_count <= write_count + 5'b1;
      training_data_reg[j] <= readdata;
      j <= j + 1;
      readaddress <= readadress + W;
      read <= 1'b0;
      
      if ( j == ((M*N) - 1)) state <= 2'b11;
    end
    2'b11: begin // DONE
      for (i = 0; i < (M*N); i <= i + 1) begin
        training_data[i] <= training_data_reg[i];
        input_data[i] <= input_data_reg[i];
      end
      data_ready <= 1'b1;
    end



