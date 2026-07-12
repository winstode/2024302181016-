`timescale 1ns/1ns

module pipecomp_tb();
  reg clk;
  reg rstn;
  wire [31:0] reg_data;
  wire [31:0] pc_debug;
  wire [31:0] sid_original;
  wire [31:0] sid_sorted;
  integer errors;
  integer i;

  pipecomp dut(.clk(clk), .rstn(rstn), .reg_sel(5'd0), .reg_data(reg_data), .pc_debug(pc_debug), .sid_original(sid_original), .sid_sorted(sid_sorted));

  initial begin
    for (i = 0; i < 128; i = i + 1) dut.U_DM.dmem[i] = 32'h0;
    clk = 1'b1;
    rstn = 1'b1;
    errors = 0;
    #10 rstn = 1'b0;
  end

  always #5 clk = ~clk;

  initial begin
    $dumpfile("pipecpu_sid_sort.vcd");
    $dumpvars(0, pipecomp_tb);
    #100000;
    if (sid_original !== 32'h0218_1016) begin
      $display("[FAIL] pipe original expected 02181016, got %h", sid_original);
      errors = errors + 1;
    end
    if (sid_sorted !== 32'h0011_1268) begin
      $display("[FAIL] pipe sorted expected 00111268, got %h", sid_sorted);
      errors = errors + 1;
    end
    $display("[RESULT] pipe_original_sid=%h", sid_original);
    $display("[RESULT] pipe_sorted_sid=%h", sid_sorted);
    if (errors == 0) $display("[PASS] lab-6 pipeline sid sorting simulation passed.");
    else $display("[FAIL] lab-6 pipeline sid sorting simulation failed with %0d error(s).", errors);
    #20 $finish;
  end
endmodule
