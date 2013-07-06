module significandMultiplier(aIn, bIn, sum, carry);
  `include "parameters.v"
  input [SIG_WIDTH:0] aIn,bIn;
  output [2*SIG_WIDTH+3:0] sum, carry; //49-bit + 1 sign bit
  
  //radix-2 Booth multiples generation
  wire [SIG_WIDTH+2:0] b, twob, minusb, minusTwob;
  assign b = {2'b0,bIn};
  assign minusb = ~{2'b0,bIn} + 1'b1;
  assign twob = {2'b0,bIn}<<1;
  assign minusTwob = minusb<<1;
  
  wire [SIG_WIDTH+3:0] aIn_zeroLSB = {2'b0,aIn,1'b0};
  wire [SIG_WIDTH+2:0] recoded [((SIG_WIDTH+1)/2):0];
  //generate partial products
  genvar i;
  generate
    for(i=1;i<=SIG_WIDTH+2;i=i+2) begin: gen_pp
       modifiedBoothRecoder MBR(aIn_zeroLSB[i-1], aIn_zeroLSB[i], aIn_zeroLSB[i+1], b, twob, minusTwob, minusb, recoded[i>>1]);
    end
  endgenerate
  
  //Multiplier carry-out detection
  wire [(SIG_WIDTH+1)/2:0] pp_signs;
  genvar c;
  generate
    for(c=0;c<(SIG_WIDTH+1)/2+1;c=c+1) begin
       assign pp_signs[c] = recoded[c][SIG_WIDTH+2];
    end
  endgenerate
  wire pp_carry_out = |pp_signs;
  
 
  //CSA array to add partial products (Single Precision tree)
  wire [SIG_WIDTH+6:0] s_a, s_b, s_c, s_d, c_a, c_b, c_c, c_d;//30-bit
  wire [SIG_WIDTH+12:0] s_e, c_e, s_f, c_f;//36-bit
  wire [SIG_WIDTH+8:0] c_g, s_g;//32-bit
  wire [SIG_WIDTH+19:0] s_h, c_h;//43-bit
  wire [SIG_WIDTH+19:0] s_i, c_i;//43-bit
  wire [SIG_WIDTH+27:0] s_final, c_final;//51-bit
  
  //Output assignments
  assign sum = s_final; assign carry = c_final;
  
  //Stage 0 (each recoded word is 26-bit)
  //26-bit inputs 30-bit outputs
  
  compressor_3_2_group #(.GRP_WIDTH(30)) comp_a({{4{recoded[0][SIG_WIDTH+2]}},recoded[0]}, 
                              {{2{recoded[1][SIG_WIDTH+2]}},recoded[1],2'b0}, 
                                {recoded[2],4'b0}, s_a, c_a);
                  
  compressor_3_2_group #(.GRP_WIDTH(30)) comp_b({{4{recoded[3][SIG_WIDTH+2]}},recoded[3]}, 
                              {{2{recoded[4][SIG_WIDTH+2]}},recoded[4],2'b0}, 
                                {recoded[5],4'b0}, s_b, c_b);
                                
  compressor_3_2_group #(.GRP_WIDTH(30)) comp_c({{4{recoded[6][SIG_WIDTH+2]}},recoded[6]}, 
                              {{2{recoded[7][SIG_WIDTH+2]}},recoded[7],2'b0}, 
                                {recoded[8],4'b0}, s_c, c_c);
                                
  compressor_3_2_group #(.GRP_WIDTH(30)) comp_d({{4{recoded[9][SIG_WIDTH+2]}},recoded[9]}, 
                              {{2{recoded[10][SIG_WIDTH+2]}},recoded[10],2'b0}, 
                              {recoded[11],4'b0}, s_d, c_d);
                              
  //Stage 1 (sign-extend sum and carry vectors with to adjust for the increased bit-width)
  //30-bit inputs, 36-bit outputs
 
  //Stage-1 CSA inputs, extended
  wire [SIG_WIDTH+12:0] s_a_ext, c_a_ext, s_b_ext; //inputs to CSA e
  wire [SIG_WIDTH+12:0] s_c_ext, c_c_ext, c_b_ext; //inputs to CSA f
  wire [SIG_WIDTH+8:0] c_d_ext, s_d_ext, pp12_ext; //inputs to CSA g
  
  assign s_a_ext = {{6{s_a[SIG_WIDTH+6]}},s_a};
  assign s_b_ext = {s_b,6'b0};
  assign c_a_ext = {{5{c_a[SIG_WIDTH+6]}},c_a,1'b0};
    
  assign s_c_ext = {{1{s_c[SIG_WIDTH+6]}},s_c,5'b0};
  assign c_c_ext = {c_c,6'b0};
  assign c_b_ext = {{6{c_b[SIG_WIDTH+6]}},c_b};
      
  assign s_d_ext = {{2{s_d[SIG_WIDTH+6]}},s_d};
  assign c_d_ext = {{1{c_d[SIG_WIDTH+6]}},c_d,1'b0};
  assign pp12_ext = {recoded[12],6'b0};
    
  compressor_3_2_group #(.GRP_WIDTH(36)) comp_e(s_a_ext,c_a_ext,s_b_ext, s_e, c_e);
                                
  compressor_3_2_group #(.GRP_WIDTH(36)) comp_f(c_b_ext, s_c_ext, c_c_ext, s_f, c_f);

  compressor_3_2_group #(.GRP_WIDTH(32)) comp_g(c_d_ext, s_d_ext, pp12_ext, s_g, c_g);

  
  //Stage 2
  //36bit inputs, 43/41-bit outputs
                               
  //Stage-2 CSA inputs, extended
  wire [SIG_WIDTH+19:0] s_e_ext, c_e_ext, s_f_ext; //inputs to CSA h (43-bit)
  wire [SIG_WIDTH+19:0] c_g_ext, s_g_ext, c_f_ext; //inputs to CSA i (43-bit)
  assign s_e_ext = {{7{s_e[SIG_WIDTH+12]}},s_e};
  assign c_e_ext = {{6{c_e[SIG_WIDTH+12]}},c_e,1'b0};
  assign s_f_ext = {s_f,7'b0};
  
  assign c_f_ext = {{11{c_f[SIG_WIDTH+12]}},c_f};
  assign s_g_ext = {{1{s_g[SIG_WIDTH+8]}},s_g,10'b0};
  assign c_g_ext = {c_g,11'b0};
  
  compressor_3_2_group #(.GRP_WIDTH(43)) comp_h(s_e_ext, c_e_ext, s_f_ext, s_h, c_h);
  compressor_3_2_group #(.GRP_WIDTH(43)) comp_i(c_f_ext, s_g_ext, c_g_ext, s_i, c_i);
  
  
  //Stage 3(4:2 compression)
  //47/43-bit input, 56-bit output
  wire [SIG_WIDTH+27:0] cout;
  //Stage-4 inputs, extended
  wire [SIG_WIDTH+27:0] s_h_ext, c_h_ext, s_i_ext, c_i_ext;
  assign s_h_ext= {{9{s_h[SIG_WIDTH+19]}},s_h};
  assign c_h_ext= {{8{c_h[SIG_WIDTH+19]}},c_h,1'b0};
  assign s_i_ext= {{1{s_i[SIG_WIDTH+19]}},s_i,8'b0};
  assign c_i_ext= {c_i,9'b0};
  
  compressor_4_2_group #(.GRP_WIDTH(51)) comp_j(s_h_ext, c_h_ext, s_i_ext, c_i_ext,
                              {cout[49:0],1'b0}, s_final, c_final, cout);
  
  
endmodule

