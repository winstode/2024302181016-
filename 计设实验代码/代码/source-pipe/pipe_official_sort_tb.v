`timescale 1ns/1ns
module pipe_official_sort_tb();
  reg clk; reg rstn; wire [31:0] reg_data; wire [31:0] pc_debug; wire [31:0] sid_original; wire [31:0] sid_sorted;
  integer i; integer errors;
  pipecomp dut(.clk(clk), .rstn(rstn), .reg_sel(5'd0), .reg_data(reg_data), .pc_debug(pc_debug), .sid_original(sid_original), .sid_sorted(sid_sorted));
  initial begin
    $readmemh("riscv_sidascsorting_sim.dat", dut.U_imem.RAM);
    for (i=0; i<128; i=i+1) dut.U_DM.dmem[i] = 32'h0;
    clk=1'b1; rstn=1'b1; errors=0; #10 rstn=1'b0;
  end
  always #5 clk=~clk;
  initial begin
    $dumpfile("pipe_official_sort.vcd"); $dumpvars(0, pipe_official_sort_tb);
    #100000;
    if (sid_original !== 32'h5487_3530) begin $display("[FAIL] pipe original expected 54873530 got %h", sid_original); errors=errors+1; end
    if (sid_sorted !== 32'h0334_5578) begin $display("[FAIL] pipe sorted expected 03345578 got %h", sid_sorted); errors=errors+1; end
    $display("[RESULT] pipe_official_original=%h", sid_original);
    $display("[RESULT] pipe_official_sorted=%h", sid_sorted);
    if (errors==0) $display("[PASS] pipeline official sid sorting simulation passed.");
    else $display("[FAIL] pipeline official sid sorting simulation failed with %0d error(s).", errors);
    #20 $finish;
  end
endmodule
