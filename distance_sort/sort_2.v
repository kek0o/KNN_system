 module sort_2 #(parameter W = 16, TYPE_W = 3)(
   input wire clk,
   input wire rst,
   input wire in_valid,
   input wire ascending,
   input wire [W-1:0] in_0, in_1,
   input wire [TYPE_W-1:0] in_0_type, in_1_type,
   output reg [W-1:0] out_0, out_1,
   output reg [TYPE_W-1:0] out_0_type, out_1_type,
   output reg out_valid
 );

 always @(posedge clk) begin
  if (rst) begin
    out_valid <= 1'b0;
    out_0 <= {W{1'b0}};
    out_0_type <= {TYPE_W{1'b0}};
    out_1_type <= {TYPE_W{1'b0}};
    out_1 <= {W{1'b0}};
  end else begin
    out_valid <= in_valid;
    if (ascending) begin
      if (in_0 < in_1 ) begin
        out_0 <= in_0;
        out_0_type <= in_0_type;
        out_1 <= in_1;
        out_1_type <= in_1_type;
      end else begin
        out_0 <= in_1;
        out_0_type <= in_1_type;
        out_1 <= in_0;
        out_1_type <= in_0_type;
      end
    end else begin
      if (in_0 > in_1 ) begin
        out_0 <= in_0;
        out_0_type <= in_0_type;
        out_1 <= in_1;
        out_1_type <= in_1_type;
      end else begin
        out_0 <= in_1;
        out_0_type <= in_1_type;
        out_1 <= in_0;
        out_1_type <= in_0_type;
      end
    end
  end
 end
 endmodule

