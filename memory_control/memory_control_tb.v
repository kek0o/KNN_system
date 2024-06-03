`timescale 10ns/1ns

module memory_control_tb;

reg clk, rst, start, data_request, done;
reg [TYPE_W-1:0] inferred_type;
reg inference_done;
reg [W-1:0] readdata;
wire read;
wire [ADDR_W-1:0] readaddress;
wire [W-1:0] writedata;
wire write;
wire [ADDR_W-1:0] writeaddress;
wire [W*MAX_ELEMENTS-1:0] input_data;
wire [W*MAX_ELEMENTS-1:0] training_data;
wire [TYPE_W-1:0] training_data_type;
wire read_done;
wire idle;
wire done_calc;

parameter L=6; // number of training matrices
parameter K=8; // number of neighbours
parameter M=6, N=2, W=16, TYPE_W = 3, MAX_ELEMENTS=32, ADDR_W=25, BASE_T_ADDR=0;
parameter BASE_I_ADDR= W*M*N*(1<<L)+W*(1<<L);


reg [W*M*N*((1<<L)+10) + W*((1<<L)+10)-1:0] sdram;
reg set_type;
reg [W-1:0] matrix_value;
integer i,j, training_elements;
integer clk_count;
integer inference_count;

// module instances
memory_control #(M,N,W,MAX_ELEMENTS,TYPE_W,1<<L,ADDR_W,BASE_T_ADDR,BASE_I_ADDR) mem_ctrl 
(clk, rst, start, data_request, done, inferred_type, inference_done, readdata,
read, readaddress, writedata, write, writeaddress, input_data, training_data, training_data_type, read_done, idle);

knn_system #(M,N,W,MAX_ELEMENTS,TYPE_W,K,L) knn 
(clk, rst, read_done, training_data, training_data_type, input_data, data_request, done, done_calc, inferred_type, inference_done);

// clk generation
initial begin
  clk = 1;
  forever #20 clk = ~clk;
end

//task definition
task set_sdram_data();
begin
  i = 0;
  training_elements = 0;
  while (i < (W*M*N*((1<<L)+10)+W*((1<<L)+10))) begin
    matrix_value = $urandom_range(0, 100);
    // set type at the first address of each matrix
    if (training_elements < (1<<L)) begin
      if (matrix_value < 20) sdram[i +:W] = 1;
      else if (matrix_value < 40) sdram[i +:W] = 2;
      else if (matrix_value < 60) sdram[i +:W] = 3;
      else if (matrix_value < 80) sdram[i +:W] = 4;
      else sdram[i +:W] = 5;
    end else sdram[i +:W] = 0; // no specific type for input data
    i = i + W;

    for (j = 0; j < (M*N); j = j + 1) sdram[(i + j*W) +:W] = matrix_value;
      i = i + W*M*N;
      training_elements = training_elements + 1;
  end
  #1;
end
endtask

task read_sdram();
begin
  @(posedge clk); // read activation
  @(posedge clk); // CAS Latency 1
  @(posedge clk); // CAS Latency 2
  readdata = sdram[readaddress +:W];
  #1;
end
endtask

task write_sdram();
begin
  clk_count = 0;
  @(posedge clk); // write activation
  sdram[writeaddress +:W] = writedata;
  while (clk_count < 8) begin // writting process
    @(posedge clk);
    clk_count = clk_count + 1;
  end
  #1;
end
endtask

task display_sdram_data();
begin
  i = 0;
  while (i < (W*M*N*((1<<L)+10)+W*((1<<L)+10))) begin
    $display("Address %0d:", i);
    if (i < BASE_I_ADDR) begin
      $display("Training Type: %0d", sdram[i +: W]);
      i = i + W;
      $display("Training Matrix value: %0d", sdram[i +: W]);
    end else begin
      $display("Input Type: %0d", sdram[i +: W]);
      i = i + W;
      $display("Input Matrix value: %0d", sdram[i +: W]);
    end
     i = i + W*M*N;
  end
end
endtask


// stimuli generation
initial begin
  rst = 1'b1;
  finish = 1'b0;
  start = 1'b0;
  readdata = 0;
  #5 rst = 1'b0;
  #100 start = 1'b1;
  @(posedge clk);
  #1;
end

always @(posedge read) read_sdram();
always @(posedge write) write_sdram();
always @(posedge done_calc) $display("Done calculating data set");

reg finish;
always @(posedge inference_done) begin
  inference_count = inference_count + 1;
  if (inference_count == 10) begin
    start = 1'b0;
    finish = 1'b1;
  end
  $display ("Inference!");
  $display("Inference number: %0d", inference_count);
end

initial begin
  $dumpfile("memory_control_tb.vcd");
  $dumpvars;
  inference_count = 0;
  clk_count = 0;
  set_sdram_data();
  display_sdram_data();
  
  @(posedge finish);
  #1000;
  display_sdram_data();
  #100; 
  $finish;
end 
endmodule
