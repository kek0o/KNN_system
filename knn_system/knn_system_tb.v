`timescale 1ns/1ps

module knn_system_tb;

parameter M = 5, N = 10, W = 32, MAX_ELEMENTS = 32, TYPE_W = 3, K = 7, L = 6;

reg clk, rst, read_done;
reg [W*MAX_ELEMENTS-1:0] training_data;
reg [TYPE_W-1:0] training_data_type;
reg [W*MAX_ELEMENTS-1:0] input_data;
wire [TYPE_W-1:0] inferred_type;
wire data_request, done, done_calc, inference_done;


reg [W*M*N-1:0] training_data_temp;
reg [W*M*N-1:0] input_data_temp;
integer i, j, i_arr;

knn_system #(M,N,W,MAX_ELEMENTS,TYPE_W,K,L) uut(clk, rst, read_done, training_data, training_data_type, input_data,
             data_request, done, done_calc, inferred_type, inference_done);

// clk generation
initial begin
  clk = 1'b1;
  forever #20 clk = ~clk;
end

//task definition
task set_training_data(input [W-1:0] matrix_value);
begin
  for (i=0; i<(M*N); i = i + 1) training_data_temp[W*(i+1)-1-:W]=matrix_value;

  if (matrix_value < 20) training_data_type = 1;
  else if (matrix_value < 40) training_data_type = 2;
  else if (matrix_value < 60) training_data_type = 3;
  else if (matrix_value < 80) training_data_type = 4;
  else training_data_type = 5;
end
endtask

task set_input_data(input [W-1:0] matrix_value);
begin
  for (i=0; i<(M*N); i = i + 1) input_data_temp[W*(i+1)-1-:W] = matrix_value;
end
endtask

task load_data(input data_stream);
  if (!data_stream) begin // M*N < MAX_ELEMENTS
    training_data=training_data_temp;
    input_data=input_data_temp;
  end else begin
    i = 0;
    j = 0;
    while (i < (M*N)) begin
      training_data[(j+1)*W-1-:W] = training_data_temp[(i+1)*W-1-:W];
      input_data[(j+1)*W-1-:W] = input_data_temp[(i+1)*W-1-:W];
      if (j < MAX_ELEMENTS) begin 
        i = i + 1;
        j = j + 1;
      end else begin // send data burst
        j = 0;
        read_done = 1'b1;
        @(posedge clk);
        #1;
        read_done = 1'b0;
        wait(data_request);
        @(posedge clk);
        #1;
      end
    end
  end
  read_done = 1'b1;
  @(posedge clk);
  #1;
  read_done = 1'b0;
  wait(done);
  @(posedge clk);
  #1;
endtask;
task set_data(input integer matrix_value, input data_stream);
begin
  set_input_data(matrix_value);
  i_arr = 0;
  while (i_arr < (1<<L)) begin
    set_training_data($urandom_range(0,100));
    load_data(data_stream);
    i_arr = i_arr + 1;
  end
  wait(inference_done);
  @(posedge clk);
  #1;
end
endtask

task display_data();
begin
  wait(done_calc);
  $display("Input data:");
  for (i = 0; i < M; i = i + 1) begin
    for (j = 0; j < N; j = j + 1) begin
      $display("input_data[%0d][%0d] = %0d", i, j, input_data_temp[W*(i*N+j+1)-1-:W]);
    end
  end
  wait(inference_done);
  $display("Inferred type = %0d", inferred_type);
end
endtask


// stimuli generation
initial begin
  i = 0;
  j = 0;
  training_data = {W*MAX_ELEMENTS{1'b0}};
  input_data = {W*MAX_ELEMENTS{1'b0}};
  rst = 1'b1;
  read_done = 1'b0;
  #5 rst = 1'b0;
  @(posedge clk);

  if ((M*N) < MAX_ELEMENTS) begin
    set_data(25,0);
    set_data(50,0);
    set_data(30,0);
    set_data(10,0);
    set_data(90,0);
  end else begin
    set_data(25,1);
    set_data(50,1);
    set_data(30,1);
    set_data(10,1);
    set_data(90,1);


  end
end

initial begin
  $dumpfile("knn_system_tb.vcd");
  $dumpvars;

  display_data();
  display_data();
  display_data();
  display_data();
  display_data(); 
  #200000;
  $finish;
end 
endmodule

