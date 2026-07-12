module pipecomp(clk, rstn, reg_sel, reg_data, pc_debug, sid_original, sid_sorted);
   input          clk, rstn;
   input [4:0]    reg_sel;
   output [31:0]  reg_data;
   output [31:0]  pc_debug;
   output [31:0]  sid_original;
   output [31:0]  sid_sorted;

   wire [31:0] instr;
   wire [31:0] PC;
   wire MemWrite;
   wire [31:0] dm_addr, dm_din, dm_dout;

   assign pc_debug = PC;

   PipeCPU U_PIPECPU(
      .clk(clk), .reset(rstn), .inst_in(instr), .Data_in(dm_dout),
      .mem_w(MemWrite), .PC_out(PC), .Addr_out(dm_addr), .Data_out(dm_din),
      .reg_sel(reg_sel), .reg_data(reg_data)
   );

   dm U_DM(
      .clk(clk), .DMWr(MemWrite), .addr(dm_addr), .din(dm_din), .dout(dm_dout),
      .sid_original(sid_original), .sid_sorted(sid_sorted)
   );

   im U_imem(.addr(PC[31:2]), .dout(instr));
endmodule
