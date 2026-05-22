/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : U-2022.12-SP4
// Date      : Mon Jul  1 17:31:11 2024
/////////////////////////////////////////////////////////////


module b01 ( line1, line2, reset, outp, overflw, clock, test_si, test_so, 
        test_se );
  input line1, line2, reset, clock, test_si, test_se;
  output outp, overflw, test_so;
  wire   stato_1_, stato_0_, N43, N44, N45, N46, n5, n7, n26, n27, n28, n29,
         n30, n31, n32, n33, n34, n35, n36, n37, n38, n39, n40, n41, n42, n43,
         n44, n45, n46, n47;

  SDFFR_X2 stato_reg_0_ ( .D(n7), .SI(overflw), .SE(test_se), .CK(clock), .RN(
        n5), .Q(stato_0_), .QN(n28) );
  SDFFR_X1 stato_reg_1_ ( .D(N43), .SI(stato_0_), .SE(test_se), .CK(clock), 
        .RN(n5), .Q(stato_1_), .QN(n26) );
  SDFFR_X2 stato_reg_2_ ( .D(N44), .SI(stato_1_), .SE(test_se), .CK(clock), 
        .RN(n5), .Q(test_so), .QN(n27) );
  SDFFR_X2 overflw_reg ( .D(N46), .SI(outp), .SE(test_se), .CK(clock), .RN(n5), 
        .Q(overflw) );
  SDFFR_X2 outp_reg ( .D(N45), .SI(test_si), .SE(test_se), .CK(clock), .RN(n5), 
        .Q(outp) );
  NAND2_X1 U29 ( .A1(n29), .A2(n30), .ZN(n7) );
  MUX2_X1 U30 ( .A(n31), .B(n32), .S(n27), .Z(n30) );
  NAND2_X1 U31 ( .A1(n33), .A2(n26), .ZN(n32) );
  XNOR2_X1 U32 ( .A(n34), .B(stato_0_), .ZN(n33) );
  NAND2_X1 U33 ( .A1(n35), .A2(n36), .ZN(n31) );
  INV_X1 U34 ( .A(n37), .ZN(n29) );
  MUX2_X1 U35 ( .A(n38), .B(N46), .S(n39), .Z(n37) );
  INV_X1 U36 ( .A(reset), .ZN(n5) );
  NOR3_X1 U37 ( .A1(n26), .A2(test_so), .A3(n28), .ZN(N46) );
  XOR2_X1 U38 ( .A(n40), .B(n41), .Z(N45) );
  NAND2_X1 U39 ( .A1(test_so), .A2(n35), .ZN(n41) );
  NAND2_X1 U40 ( .A1(n39), .A2(n36), .ZN(n40) );
  MUX2_X1 U41 ( .A(n42), .B(n43), .S(n27), .Z(N44) );
  NAND2_X1 U42 ( .A1(n39), .A2(n35), .ZN(n43) );
  INV_X1 U43 ( .A(n38), .ZN(n35) );
  AOI21_X1 U44 ( .B1(n44), .B2(n28), .A(stato_1_), .ZN(n42) );
  OAI211_X1 U45 ( .C1(n27), .C2(n45), .A(n46), .B(n47), .ZN(N43) );
  NAND3_X1 U46 ( .A1(n39), .A2(n26), .A3(stato_0_), .ZN(n47) );
  OAI21_X1 U47 ( .B1(n34), .B2(n27), .A(n38), .ZN(n46) );
  NOR2_X1 U48 ( .A1(n26), .A2(stato_0_), .ZN(n38) );
  INV_X1 U49 ( .A(n39), .ZN(n34) );
  NAND2_X1 U50 ( .A1(line2), .A2(line1), .ZN(n39) );
  MUX2_X1 U51 ( .A(stato_1_), .B(n28), .S(n36), .Z(n45) );
  INV_X1 U52 ( .A(n44), .ZN(n36) );
  NOR2_X1 U53 ( .A1(line1), .A2(line2), .ZN(n44) );
endmodule

