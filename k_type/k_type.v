module k_type #(K, TYPE_W)(
  input wire clk,
  input wire rst,
  input wire valid_sort,
  input wire [TYPE_W*K-1:0] k_nearest_neighbours_type, // Packed array
  output reg [TYPE_W-1:0] inferred_type,
  output reg inference_done
);

  reg [1:0] state;
  reg stop;
  integer count [0:(1 << TYPE_W)-1]; // 2^TYPE_W
  integer max_type;
  integer i, j;

  always @(posedge clk) begin
    if (rst) begin
      inference_done <= 1'b0;
      stop <= 1'b0;
      inferred_type <= {TYPE_W{1'b0}};
      max_type <= 0;

      for (i = 0; i < (1 << TYPE_W); i = i + 1) count[i] <= 0;
      j <= 0;

      state <= 2'b00;
    end else begin
      case (state)
        2'b00: begin // IDLE
          inference_done <= 1'b0;
          max_type <= 0;
          for (i = 0; i < (1 << TYPE_W); i = i + 1) count[i] <= 0;
          j <= 0;

          state <= valid_sort ? 2'b01 : 2'b00;
        end
        2'b01: begin // INFER
          if (!stop) begin
            if (j < K) begin
              count[k_nearest_neighbours_type[(j+1)*TYPE_W-1 -: TYPE_W]] <= count[k_nearest_neighbours_type[(j+1)*TYPE_W-1 -: TYPE_W]] + 1;
              j <= j + 1;
            end else begin
              j <= 0;
              stop <= 1'b1;
            end
          end else begin
            if (j < (1 << TYPE_W)) begin
              if (count[j] > count[max_type]) max_type <= j;
              j <= j + 1;
            end else begin
              state <= 2'b10;
              stop <= 1'b0;
            end
          end
        end
        2'b10: begin // DONE
          inferred_type <= max_type;
          inference_done <= 1'b1;
          state <= 2'b00;
        end
      endcase
    end
  end
endmodule


