 module sort_2 #(parameter W)(
   input wire [W-1:0] A, B, A_type, B_type,
   output wire [W-1:0] H, L, H_type, L_type
 );

  assign a_bigger = A > B;
  assign H = a_bigger ? A : B;
  assign L = a_bigger ? B : A;
  assign H_type = a_bigger ? A_type : B_type;
  assign L_type = a_bigger ? B_type : A_type;

 // assign {H,L} = (A > B) ? {A,B} : {B,A}; not used due to synthesis problem
 // derived from concatenating real operands

 endmodule

