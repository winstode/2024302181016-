`timescale 1ns/1ns
module pipe_test30_tb();
  reg clk; reg rstn; wire [31:0] reg_data; wire [31:0] pc_debug; wire [31:0] sid_original; wire [31:0] sid_sorted;
  integer i; integer errors;
  pipecomp dut(.clk(clk), .rstn(rstn), .reg_sel(5'd0), .reg_data(reg_data), .pc_debug(pc_debug), .sid_original(sid_original), .sid_sorted(sid_sorted));
  initial begin
    $readmemh("Test_30_Instr.dat", dut.U_imem.RAM);
    for (i=0; i<128; i=i+1) dut.U_DM.dmem[i] = 32'h0;
    clk=1'b1; rstn=1'b1; errors=0; #10 rstn=1'b0;
  end
  always #5 clk = ~clk;
  task check; input [1023:0] name; input [31:0] got; input [31:0] exp; begin
    if (got !== exp) begin $display("[FAIL] %0s expected %h got %h", name, exp, got); errors=errors+1; end
    else $display("[OK] %0s=%h", name, got);
  end endtask
  initial begin
    $dumpfile("pipe_test30.vcd"); $dumpvars(0, pipe_test30_tb);
    #10000;
    check("mem[0]", dut.U_DM.dmem[0], 32'h0000_000c);
    check("x5", dut.U_PIPECPU.U_RF.rf[5], 32'h9876_3dcc);
    check("x7", dut.U_PIPECPU.U_RF.rf[7], 32'h0000_1236);
    check("x9", dut.U_PIPECPU.U_RF.rf[9], 32'h0000_000c);
    check("x19", dut.U_PIPECPU.U_RF.rf[19], 32'h9876_3dcc);
    if (errors==0) $display("[PASS] pipeline Test_30_Instr passed.");
    else $display("[FAIL] pipeline Test_30_Instr failed with %0d error(s).", errors);
    #20 $finish;
  end
endmodule
