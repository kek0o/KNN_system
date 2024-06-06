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
  reg [32*(1<<TYPE_W)-1:0] count; // 2^TYPE_W
  reg [TYPE_W-1:0] max_type;
  reg [TYPE_W:0] j;
  reg [TYPE_W-1:0] index;

  always @(posedge clk) begin
    if (rst) begin
      inference_done <= 1'b0;
      stop <= 1'b0;
      inferred_type <= {TYPE_W{1'b0}};
      max_type <= 0;
      count <= {32*(1<<TYPE_W){1'b0}};
      index <= {TYPE_W{1'b0}};
      j <= 0;
      state <= 2'b00;
    end else begin
      case (state)
        2'b00: begin // IDLE
          inference_done <= 1'b0;
          max_type <= 0;
          count <= {32*(1<<TYPE_W){1'b0}};
          j <= 0;
          if (valid_sort) begin
            index <= k_nearest_neighbours_type[(j+1)*TYPE_W-1-:TYPE_W];
            state <= 2'b01;
          end else index <= {TYPE_W{1'b0}};

        end
        2'b01: begin // INFER
          if (!stop) begin
            count[32*(index+1)-1-:32] <= count[32*(index+1)-1-:32] + 1;
            index <= k_nearest_neighbours_type[(j+1)*TYPE_W-1-:TYPE_W];
            if (j < K) begin
              j <= j + 1'b1;
            end else begin
              j <= 0;
              stop <= 1'b1;
            end
          end else begin
            if (j < (1 << TYPE_W)) begin
              if (count[32*(j+1)-1-:32] > count[32*(max_type+1)-1-:32]) max_type <= j;
              j <= j + 1'b1;
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


