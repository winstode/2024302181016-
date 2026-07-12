`timescale 1ns/1ns
module sc_official_sort_tb();
  reg clk; reg rstn; reg [4:0] reg_sel; wire [31:0] reg_data;
  integer i; integer errors;
  sccomp dut(.clk(clk), .rstn(rstn), .reg_sel(reg_sel), .reg_data(reg_data));
  initial begin
    $readmemh("riscv_sidascsorting_sim.dat", dut.U_imem.RAM);
    for (i=0; i<128; i=i+1) dut.U_DM.dmem[i] = 32'h0;
    clk=1'b1; rstn=1'b1; reg_sel=5'd0; errors=0; #10 rstn=1'b0;
  end
  always #5 clk=~clk;
  initial begin
    $dumpfile("sc_official_sort.vcd"); $dumpvars(0, sc_official_sort_tb);
    #20000;
    if (dut.U_DM.dmem[96] !== 32'h5487_3530) begin $display("[FAIL] original expected 54873530 got %h", dut.U_DM.dmem[96]); errors=errors+1; end
    if (dut.U_DM.dmem[97] !== 32'h0334_5578) begin $display("[FAIL] sorted expected 03345578 got %h", dut.U_DM.dmem[97]); errors=errors+1; end
    $display("[RESULT] official_original=%h", dut.U_DM.dmem[96]);
    $display("[RESULT] official_sorted=%h", dut.U_DM.dmem[97]);
    if (errors==0) $display("[PASS] sc official sid sorting simulation passed.");
    else $display("[FAIL] sc official sid sorting simulation failed with %0d error(s).", errors);
    #20 $finish;
  end
endmodule
