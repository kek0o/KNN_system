`timescale 10ns/1ns
`include "distance_calculator.v"

module distance_calculator_tb;

reg clk, rst, ready;
reg [W-1:0] training_data [0:(M*N)-1];
reg [TYPE_W-1:0] training_data_type;
reg [W-1:0] input_data [0:(M*N)-1];
wire [W-1:0] distance;
wire [TYPE_W-1:0] data_type;
wire done;

parameter M=60, N=10, W=32, MAX_ELEMENTS=30, TYPE_W=2;

reg [W-1:0] training_data_temp [0:(M*N)-1];
reg [W-1:0] input_data_temp [0:(M*N)-1];
integer i,j;

distance_calculator #(M,N,W,MAX_ELEMENTS,TYPE_W) uut(clk, rst, ready, training_data, training_data_type, input_data,distance, data_type, done, data_request);

// clk generation
initial begin
  clk = 1;
  forever #20 clk = ~clk;
end

//task definition
task set_data(input integer range, input data_stream);
  training_data_type = $urandom_range(0,3);
  for (integer i=0; i<(M*N); i=i+1) begin
    training_data_temp[i]=$urandom_range(0,range);
    input_data_temp[i]=$urandom_range(0,range);
  end

  if (!data_stream) begin // M*N < MAX_ELEMENTS
    for (integer i=0; i<(M*N); i=i+1) begin
      training_data[i]=training_data_temp[i];
      input_data[i]=input_data_temp[i];
    end
    ready = 1'b1;
    @(posedge clk);
    #1;
    ready = 1'b0;
    wait(done);
    @(posedge clk);
    #1;
  end else begin
    i = 0;
    j = 0;
    while (i < (M*N)) begin
      training_data[j] = training_data_temp[i];
      input_data[j] = input_data_temp[i];
      i = i + 1;
      if (j < MAX_ELEMENTS) begin 
        j = j + 1;
      end else begin // data burst
        j = 0;
        ready = 1'b1;
        @(posedge clk);
        #1;
        ready = 1'b0;
        wait(data_request);
        @(posedge clk);
        #1;
      end
    end

    ready = 1'b1;
    @(posedge clk);
    #1;
    ready = 1'b0;
    wait(done);
    @(posedge clk);
    #1;
  end
endtask

task simple_data_test(input data_stream);
  training_data_type = $urandom_range(0,3);
  for (integer i=0; i<(M*N); i=i+1) begin
    training_data_temp[i]=1;
    input_data_temp[i]=0;
  end

  if (!data_stream) begin // M*N < MAX_ELEMENTS
    for (integer i=0; i<(M*N); i=i+1) begin
      training_data[i]=training_data_temp[i];
      input_data[i]=input_data_temp[i];
    end
    ready = 1'b1;
    @(posedge clk);
    #1;
    ready = 1'b0;
    wait(done);
    @(posedge clk);
    #1;
  end else begin
    i = 0;
    j = 0;
    while (i < (M*N)) begin
      training_data[j] = training_data_temp[i];
      input_data[j] = input_data_temp[i];
      i = i + 1;
      if (j < MAX_ELEMENTS) begin 
        j = j + 1;
      end else begin // data burst
        j = 0;
        ready = 1'b1;
        @(posedge clk);
        #1;
        ready = 1'b0;
        wait(data_request);
        @(posedge clk);
        #1;
      end
    end

    ready = 1'b1;
    @(posedge clk);
    #1;
    ready = 1'b0;
    wait(done);
    @(posedge clk);
    #1;
  end
endtask


task display_data();
  wait(ready);
  $display("Training data:");
  for (int i = 0; i < M; i = i + 1) begin
    for (int j = 0; j < N; j = j + 1) begin
      $display("training_data[%0d][%0d] = %0d", i, j, training_data_temp[i*N+j]);
    end
  end
  $display("Training data type: %0d", training_data_type);

  $display("Input data:");
  for (int i = 0; i < M; i = i + 1) begin
    for (int j = 0; j < N; j = j + 1) begin
      $display("input_data[%0d][%0d] = %0d", i, j, input_data_temp[i*N+j]);
    end
  end
  wait(done);
  $display("distance = %0d", distance); 
endtask

// stimuli generation
initial begin
  rst = 1'b1;
  ready = 1'b0;
  #5 rst = 1'b0;
  @(posedge clk);
  
  if ((M*N) < MAX_ELEMENTS) begin
    set_data(100,0);
    set_data(200,0);
    set_data(300,0);
    simple_data_test(0);
  end else begin
    set_data(100,1);
    set_data(200,1);
    set_data(300,1);
    simple_data_test(1);
  end
end

initial begin
  $dumpfile("distance_calculator_tb.vcd");
  $dumpvars;

  display_data();
  display_data();
  display_data();
  display_data();

  #20000;
  $finish;
end 
endmodule
