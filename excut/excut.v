module excut (A, B, C, D, E, test_si, reset, clock, test_se, X, Y, Z, test_so);
  input A, B, C, D, E, test_si, reset, clock, test_se;
  output X, Y, Z, test_so;
  wire wire0, wire1, wire2, wire3, wire4, wire5, chain, rst0;

  SDFFR_X1 reg0 ( .D(wire0), .SI(test_si), .SE(test_se), .CK(clock), .RN(rst0), .Q(chain), .QN(wire4) );
  SDFFR_X2 reg1 ( .D(wire3), .SI(chain), .SE(test_se), .CK(clock), .RN(rst0), .Q(test_so), .QN(Z) );
  INV_X1 RESET0 ( .A(reset), .ZN(rst0) );
  NAND2_X1 G0 ( .A1(A), .A2(B), .ZN(wire0) );
  INV_X1 G1 ( .A(C), .ZN(Y) );
  NOR3_X2 G2 ( .A1(wire0), .A2(Y), .A3(E), .ZN(wire1) );
  NOR2_X1 G3 ( .A1(wire1), .A2(D), .ZN(wire2) );
  NAND2_X1 G4 ( .A1(wire2), .A2(E), .ZN(wire3) );
  NAND2_X1 G5 ( .A1(chain), .A2(test_so), .ZN(wire5) );
  XNOR2_X1 G6 ( .A(wire5), .B(wire4), .ZN(X) );
endmodule
