`timescale 10ns/1ns

module knn_test_tb;

reg clk, rst, start_button;
reg [W-1:0] readdata;
wire read;
wire [ADDR_W-1:0] readaddress;
wire [W-1:0] writedata;
wire write;
wire [ADDR_W-1:0] writeaddress;
wire idle, sdram_write_complete, inference_done;
wire [TYPE_W-1:0] inferred_type;

parameter L=5; // number of training matrices
parameter K=8; // number of neighbours
parameter M=6, N=4, W=16, TYPE_W = 3, MAX_ELEMENTS=16, ADDR_W=25, BASE_T_ADDR=0;
parameter BASE_I_ADDR= W*M*N*(1<<L)+W*(1<<L);


reg [W*M*N*((1<<L)+10) + W*((1<<L)+10)-1:0] sdram;
reg set_type;
reg [W-1:0] matrix_value;
integer i,j, training_elements;
integer clk_count;
integer inference_count;

// module instances
knn_test #(M,N,W,MAX_ELEMENTS,TYPE_W,K,L,ADDR_W,BASE_T_ADDR,BASE_I_ADDR) uut 
(clk,rst,start_button,readdata,read,readaddress,writedata,write,writeaddress,
  idle,sdram_write_complete, inference_done, inferred_type);

// clk generation
initial begin
  clk = 1;
  forever #20 clk = ~clk;
end

//task definition

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
  clk_count = 0;
  @(posedge clk);
  sdram[writeaddress +:W] = writedata;
  while (clk_count < 8) begin // simulate writting process
    @(posedge clk);
    clk_count = clk_count + 1;
  end
  #1;
endtask

task simulate_button();
  start_button <= 1'b0;
  @(posedge clk);
  @(posedge clk);
  @(posedge clk);
  start_button <= 1'b1;
  #1;
endtask

task display_sdram_data();
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
endtask


// stimuli generation
initial begin
  rst = 1'b1;
  sdram = {W*M*N*((1<<L)+10) + W*((1<<L)+10){1'b0}};
  i = 0;
  start_button = 1'b1;
  readdata = 0;
  #5 rst = 1'b0;
  wait (sdram_write_complete);
  start_button = 1'b0;
  wait (!idle);
  start_button <= 1'b1;
end

always @(posedge read) read_sdram();
always @(posedge write) write_sdram();
always @(posedge idle) if (inference_count < 10) if (sdram_write_complete) simulate_button();

always @(posedge inference_done) begin
  inference_count = inference_count + 1;
  $display ("Inference!");
  $display("Inference number: %0d", inference_count);
end

initial begin
  $dumpfile("knn_test_tb.vcd");
  $dumpvars;
  inference_count = 0;
  clk_count = 0;

  wait(sdram_write_complete);
  display_sdram_data();
  wait(inference_count == 10);
  wait (idle);
  display_sdram_data();
  #200000;
  $finish;
end 
endmodule
