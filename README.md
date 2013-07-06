Binary Single Precision Floating-point Fused Multiply-Add Unit Design with Custom Multipier (Verilog HDL)

-- input operands A,B, C --> result: A*B+C -- for subtraction, flip the sign bit of C operand appropriately. 
-- Support IEEE-754 Round-to-zero, Round-to-nearest and Round-to-nearest-even rounding modes 
-- Implements a tree multiplier for significand multiplication with 3:2 compressors and a final 4:2 compressor. 
-- Test inputs for the design are generated using C code. 
   The Hex values written by the C code are read by the Verilog testbench (t_fpfma.v).
