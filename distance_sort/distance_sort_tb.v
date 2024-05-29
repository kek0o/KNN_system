`timescale 10ns/1ns
`include "distance_sort.v"
`include "sort_2.v"

module distance_sort_tb;

  reg clk, rst, done;
  reg [W*N-1:0] distance_array;
  reg [TYPE_W*N-1:0] type_array;

  wire [W*N-1:0] distance_array_sorted;
  wire [TYPE_W*N-1:0] type_array_sorted;
  wire valid_sort;

  integer i;
  parameter N = 64, W = 32, TYPE_W = 3;

  distance_sort #(N, W, TYPE_W) uut (
    .clk(clk),
    .rst(rst),
    .done(done),
    .distance_array(distance_array),
    .type_array(type_array),
    .distance_array_sorted(distance_array_sorted),
    .type_array_sorted(type_array_sorted),
    .valid_sort(valid_sort)
  );

  // clk generation
  initial begin
    clk = 1;
    forever #20 clk = ~clk;
  end

  // task definition
  task set_input_array(input integer range);
    begin
      for (i = 0; i < N; i = i + 1) begin
        distance_array[(i+1)*W-1 -: W] = $urandom_range(0, range);
        $display("Hola");
        if (distance_array[(i+1)*W-1 -: W] < 20) type_array[(i+1)*TYPE_W-1 -: TYPE_W] = 1;
        else if (distance_array[(i+1)*W-1 -: W] < 40) type_array[(i+1)*TYPE_W-1 -: TYPE_W] = 2;
        else if (distance_array[(i+1)*W-1 -: W] < 60) type_array[(i+1)*TYPE_W-1 -: TYPE_W] = 3;
        else if (distance_array[(i+1)*W-1 -: W] < 80) type_array[(i+1)*TYPE_W-1 -: TYPE_W] = 4;
        else type_array[(i+1)*TYPE_W-1 -: TYPE_W] = 5;
      end
      done = 1'b1;
      @(posedge clk);
      #1;
      done = 1'b0;
      wait(valid_sort);
      @(posedge clk);
      #1;
    end
  endtask

  task display_array();
    begin
      wait(done);
      $display("distance&type_array = ");
      for (i = 0; i < N; i = i + 1) begin
        $display("%0d, %0d", distance_array[(i+1)*W-1 -: W], type_array[(i+1)*TYPE_W-1 -: TYPE_W]);
      end
      #200;
      wait(valid_sort);
      $display("Sorted distance&type_array =");
      for (i = 0; i < N; i = i + 1) begin
        $display("%0d, %0d", distance_array_sorted[(i+1)*W-1 -: W], type_array_sorted[(i+1)*TYPE_W-1 -: TYPE_W]);
      end
    end
  endtask

  // stimuli generation
  initial begin
    rst = 1'b1;
    done = 1'b0;
    #5 rst = 1'b0;
    @(posedge clk);
    $display("Holaa");

    set_input_array(100);
  end

  initial begin
    $dumpfile("distance_sort_tb.vcd");
    $dumpvars;
    display_array();
    #20000 $finish;
  end
endmodule

