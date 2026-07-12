`include "ctrl_encode_def.v"
// data memory
module dm(clk, DMWr, addr, din, dout, sid_original, sid_sorted);
   input          clk;
   input          DMWr;
   input  [31:0]  addr;
   input  [31:0]  din;
   output reg [31:0]  dout;
   output [31:0] sid_original;
   output [31:0] sid_sorted;
   
   reg [31:0] dmem[127:0];
   
   always @(posedge clk)
      if (DMWr) begin
         dmem[addr[8:2]] <= din;
      end
   
     //load
     always @(*) begin
         dout <= dmem[addr[8:2]];
     end

   assign sid_original = dmem[96]; // byte address 0x180
   assign sid_sorted   = dmem[97]; // byte address 0x184
     
endmodule    
