// instruction memory
module im(input  [31:2]  addr, output [31:0] dout);
  reg  [31:0] RAM[127:0];

  initial begin
    $readmemh("rv32_sid_sort_sim.dat", RAM);
  end

  assign dout = RAM[addr]; // word aligned
endmodule  
