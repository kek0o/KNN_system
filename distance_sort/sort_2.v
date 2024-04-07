 module sort_2(
   input real A, B,
   output real H, L
 );

  assign a_bigger = A > B;
  assign H = a_bigger ? A : B;
  assign L = a_bigger ? B : A;

 // assign {H,L} = (A > B) ? {A,B} : {B,A}; not used due to synthesis problem
 // derived from concatenating real operands

 endmodule

