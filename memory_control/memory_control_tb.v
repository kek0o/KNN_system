`timescale 10ns/1ns

module memory_control_tb;

reg clk, rst, start, data_request, done, done_calc;
reg [W-1:0] inferred_type;
reg inference_done;
reg [W-1:0] readdata;
wire read;
wire [ADDR_W-1:0] readaddress;
wire [W-1:0] writedata;
wire write;
wire [ADDR_W-1:0] writeaddress;
wire [W-1:0] input_data [0:(M*N)-1];
wire [W-1:0] training_data [0:(M*N)-1];
wire [W-1:0] training_data_type;
wire read_done;

parameter L=64; // number of training matrices
parameter K=7; // number of neighbours
parameter M=6, N=10, W=16, MAX_ELEMENTS=32, ADDR_W=25, BASE_T_ADDR=0, BASE_I_ADDR= W*M*N*L;

reg [W*M*N*(L+10)-1:0] sdram;
reg set_type;
reg [W-1:0] matrix_value;
integer i,j, training_elements, data_elements;
integer clk_count;
integer inference_count;
reg rw_sdram;

// module instances
memory_control #(M,N,W,MAX_ELEMENTS,ADDR_W,BASE_T_ADDR,BASE_I_ADDR) mem_ctrl 
(clk, rst, start, data_request, done, done_calc, inferred_type, inference_done, readdata,
read, readaddress, writedata, write, writeaddress, input_data, training_data, training_data_type, read_done);

knn_system #(M,N,W,MAX_ELEMENTS,W,K,L) knn 
(clk, rst, read_done, training_data, training_data_type, input_data, data_request, done, done_calc, inferred_type, inference_done);

// clk generation
initial begin
  clk = 1;
  forever #20 clk = ~clk;
end

//task definition
task set_sdram_data();
  set_type = 1'b1;
  i = 0;
  training_elements = 0;
  while (i < W*M*N*(L+10)) begin
    matrix_value = $urandom_range(0, (1<<W)-1);
    if (set_type) begin
      // set type at the first address of each training matrix
      if (training_elements < L) begin
        if (matrix_value < ((1<<W)/5)) sdram[i +:W] = 5;
        else if (matrix_value < ((1<<W)/4)) sdram[i +:W] = 4;
        else if (matrix_value < ((1<<W)/3)) sdram[i +:W] = 3;
        else if (matrix_value < ((1<<W)/2)) sdram[i +:W] = 2;
        else sdram[i +:W] = 1;
      end else sdram[i +:W] = 0; // no specific type for input data

      set_type = 1'b0;
      i = i + W;
    end else begin
        for (j = 0; j < (M*N); j = j + 1) sdram[(i + j*W) +:W] = matrix_value;
        i = i + W*M*N;
        set_type = 1'b1;
        training_elements = training_elements + 1;
    end
  end
  #1;
endtask

task read_sdram();
  readdata = sdram[readaddress +:W];
  #1;
endtask

task write_sdram();
  clk_count = 0;
  sdram[writeaddress +:W] = writedata;
  while (clk_count < 8) begin // simulate writting process
    @(posedge clk);
    clk_count = clk_count + 1;
  end
  #1;
endtask

task display_sdram_data();
  i = 0;
  clk_count = 0;
  data_elements = 0;
  while (data_elements < (L + 10) - 1) begin
    $display("Address %0d:", i);
    if (data_elements < L) begin
      $display("Training Type: %0d", sdram[i +: W]);
      i = i + W;
      $display("Training Matrix value: %0d", sdram[i +: W]);
    end else begin
      $display("Input Type: %0d", sdram[i +: W]);
      i = i + W;
      $display("Input Matrix value: %0d", sdram[i +: W]);
    end
    data_elements = data_elements + 1;
     i = i + W*M*N;
  end

endtask

// stimuli generation
initial begin
  rst = 1'b1;
  start = 1'b0;
  readdata = 0;
  #5 rst = 1'b0;
  #100 start = 1'b1;
  @(posedge clk);
  #1;
  start = 1'b0;
end

assign rw_sdram = read | write;
always @(rw_sdram) begin
  if (read) begin
    read_sdram();
    #1;
    $display("%0d", readdata);
  end else begin
    write_sdram();
  end
end

always @(posedge clk) if (inference_done) inference_count <= inference_count + 1;

initial begin
  $dumpfile("memory_control_tb.vcd");
  $dumpvars;
  inference_count = 0;
  set_sdram_data();
  display_sdram_data();

  if (inference_count == 9) begin
    @(posedge clk);
      display_sdram_data();
      #100; 
      $finish;
  end
end 
endmodule
