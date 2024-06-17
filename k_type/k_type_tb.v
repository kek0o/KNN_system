`timescale 10ns/1ns

`include "k_type.v"

module k_type_tb;

  reg clk, rst, valid_sort;
  reg [K*TYPE_W-1:0] k_nearest_neighbours_type; // Packed array
  wire [TYPE_W-1:0] inferred_type;
  wire inference_done;
  integer i;

  parameter K=5, TYPE_W = 4;

  k_type #(K, TYPE_W) uut(clk, rst, valid_sort, k_nearest_neighbours_type, inferred_type, inference_done);

  // clk generation
  initial begin
    clk = 1;
    forever #20 clk = ~clk;
  end

  // task definition
  task set_type_array();
    begin
      for (i = 0; i < K; i = i + 1) begin
        k_nearest_neighbours_type[(i+1)*TYPE_W-1 -: TYPE_W] = $urandom_range(0, 10);
      end
      valid_sort = 1'b1;
      @(posedge clk);
      #1;
      valid_sort = 1'b0;
      wait(inference_done);
      @(posedge clk);
      #1;
    end
  endtask

  task display_type_array();
    begin
      wait(valid_sort);
      $display("Type array:");
      for (i = 0; i < K; i = i + 1) begin
        $display("k_nearest_neighbours_type[%0d] = %0d", i, k_nearest_neighbours_type[(i+1)*TYPE_W-1 -: TYPE_W]);
      end
      wait(inference_done);
      $display("Inferred type: %0d", inferred_type);
    end
  endtask

  // stimuli generation
  initial begin
    rst = 1'b1;
    valid_sort = 1'b0;
    #5 rst = 1'b0;
    @(posedge clk);

    set_type_array();
    set_type_array();
    set_type_array();
  end

  initial begin
    $dumpfile("k_type_tb.vcd");
    $dumpvars;

    display_type_array();
    display_type_array();
    display_type_array();

    #2000 $finish;
  end

endmodule

