`include "ctrl_encode_def.v"

module PipeCPU(
    input clk,
    input reset,
    input [31:0] inst_in,
    input [31:0] Data_in,
    output mem_w,
    output [31:0] PC_out,
    output [31:0] Addr_out,
    output [31:0] Data_out,
    input [4:0] reg_sel,
    output [31:0] reg_data
);
    reg [31:0] pc;
    assign PC_out = pc;

    wire [31:0] if_pc4 = pc + 32'd4;

    reg [31:0] ifid_pc;
    reg [31:0] ifid_pc4;
    reg [31:0] ifid_inst;
    reg ifid_valid;

    wire [6:0] id_op = ifid_inst[6:0];
    wire [6:0] id_funct7 = ifid_inst[31:25];
    wire [2:0] id_funct3 = ifid_inst[14:12];
    wire [4:0] id_rs1 = ifid_inst[19:15];
    wire [4:0] id_rs2 = ifid_inst[24:20];
    wire [4:0] id_rd = ifid_inst[11:7];

    wire id_regwrite;
    wire id_memwrite;
    wire [5:0] id_extop;
    wire [4:0] id_aluop;
    wire [2:0] id_npcop_unused;
    wire id_alusrc;
    wire [1:0] id_wdsel;
    wire id_zero_dummy;

    ctrl U_CTRL(
        .Op(id_op), .Funct7(id_funct7), .Funct3(id_funct3), .Zero(id_zero_dummy),
        .RegWrite(id_regwrite), .MemWrite(id_memwrite), .EXTOp(id_extop),
        .ALUOp(id_aluop), .NPCOp(id_npcop_unused), .ALUSrc(id_alusrc), .WDSel(id_wdsel)
    );

    assign id_zero_dummy = 1'b0;

    wire [11:0] id_iimm = ifid_inst[31:20];
    wire [11:0] id_simm = {ifid_inst[31:25], ifid_inst[11:7]};
    wire [11:0] id_bimm = {ifid_inst[31], ifid_inst[7], ifid_inst[30:25], ifid_inst[11:8]};
    wire [19:0] id_uimm = ifid_inst[31:12];
    wire [19:0] id_jimm = {ifid_inst[31], ifid_inst[19:12], ifid_inst[20], ifid_inst[30:21]};
    wire [31:0] id_imm;

    EXT U_EXT(.iimm(id_iimm), .simm(id_simm), .bimm(id_bimm), .uimm(id_uimm), .jimm(id_jimm), .EXTOp(id_extop), .immout(id_imm));

    wire [31:0] rf_rd1;
    wire [31:0] rf_rd2;
    wire wb_regwrite;
    wire [4:0] wb_rd;
    wire [31:0] wb_wd;

    RF U_RF(
        .clk(clk), .rst(reset), .RFWr(wb_regwrite), .A1(id_rs1), .A2(id_rs2), .A3(wb_rd),
        .WD(wb_wd), .RD1(rf_rd1), .RD2(rf_rd2), .reg_sel(reg_sel), .reg_data(reg_data)
    );

    wire [31:0] id_rd1_val = (wb_regwrite && (wb_rd != 5'd0) && (wb_rd == id_rs1)) ? wb_wd : rf_rd1;
    wire [31:0] id_rd2_val = (wb_regwrite && (wb_rd != 5'd0) && (wb_rd == id_rs2)) ? wb_wd : rf_rd2;
    wire id_is_branch = (id_op == 7'b1100011);
    wire id_is_jal = (id_op == 7'b1101111);
    wire id_is_jalr = (id_op == 7'b1100111);

    reg [31:0] idex_pc;
    reg [31:0] idex_pc4;
    reg [31:0] idex_rd1;
    reg [31:0] idex_rd2;
    reg [31:0] idex_imm;
    reg [4:0] idex_rs1;
    reg [4:0] idex_rs2;
    reg [4:0] idex_rd;
    reg [4:0] idex_aluop;
    reg idex_alusrc;
    reg idex_regwrite;
    reg idex_memwrite;
    reg [1:0] idex_wdsel;
    reg idex_is_branch;
    reg idex_is_jal;
    reg idex_is_jalr;
    reg idex_valid;

    reg [31:0] exmem_alu;
    reg [31:0] exmem_store;
    reg [31:0] exmem_pc4;
    reg [4:0] exmem_rd;
    reg exmem_regwrite;
    reg exmem_memwrite;
    reg [1:0] exmem_wdsel;
    reg exmem_valid;

    reg [31:0] memwb_alu;
    reg [31:0] memwb_mem;
    reg [31:0] memwb_pc4;
    reg [4:0] memwb_rd;
    reg memwb_regwrite;
    reg [1:0] memwb_wdsel;
    reg memwb_valid;

    assign wb_rd = memwb_rd;
    assign wb_regwrite = memwb_valid && memwb_regwrite;
    assign wb_wd = (memwb_wdsel == `WDSel_FromMEM) ? memwb_mem :
                   (memwb_wdsel == `WDSel_FromPC)  ? memwb_pc4 :
                                                      memwb_alu;

    wire exmem_can_forward = exmem_valid && exmem_regwrite && (exmem_rd != 5'd0) && (exmem_wdsel != `WDSel_FromMEM);
    wire memwb_can_forward = memwb_valid && memwb_regwrite && (memwb_rd != 5'd0);

    wire [31:0] fwd_a = (exmem_can_forward && exmem_rd == idex_rs1) ? ((exmem_wdsel == `WDSel_FromPC) ? exmem_pc4 : exmem_alu) :
                        (memwb_can_forward && memwb_rd == idex_rs1) ? wb_wd :
                                                                       idex_rd1;
    wire [31:0] fwd_b_raw = (exmem_can_forward && exmem_rd == idex_rs2) ? ((exmem_wdsel == `WDSel_FromPC) ? exmem_pc4 : exmem_alu) :
                            (memwb_can_forward && memwb_rd == idex_rs2) ? wb_wd :
                                                                           idex_rd2;
    wire [31:0] alu_b = idex_alusrc ? idex_imm : fwd_b_raw;
    wire [31:0] ex_alu;
    wire ex_zero;

    alu U_ALU(.A(fwd_a), .B(alu_b), .ALUOp(idex_aluop), .C(ex_alu), .Zero(ex_zero));

    wire take_branch = idex_valid && idex_is_branch && ex_zero;
    wire take_jal = idex_valid && idex_is_jal;
    wire take_jalr = idex_valid && idex_is_jalr;
    wire redirect = take_branch || take_jal || take_jalr;
    wire [31:0] redirect_pc = take_jalr ? ((fwd_a + idex_imm) & 32'hffff_fffe) : (idex_pc + idex_imm);

    wire load_use = idex_valid && (idex_wdsel == `WDSel_FromMEM) && (idex_rd != 5'd0) && ifid_valid &&
                    ((idex_rd == id_rs1) || (idex_rd == id_rs2));

    assign mem_w = exmem_valid && exmem_memwrite;
    assign Addr_out = exmem_alu;
    assign Data_out = exmem_store;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'b0;
            ifid_valid <= 1'b0;
            ifid_pc <= 32'b0;
            ifid_pc4 <= 32'b0;
            ifid_inst <= 32'b0;
            idex_valid <= 1'b0;
            exmem_valid <= 1'b0;
            memwb_valid <= 1'b0;
        end else begin
            if (redirect) pc <= redirect_pc;
            else if (!load_use) pc <= if_pc4;

            if (redirect) begin
                ifid_valid <= 1'b0;
            end else if (!load_use) begin
                ifid_pc <= pc;
                ifid_pc4 <= if_pc4;
                ifid_inst <= inst_in;
                ifid_valid <= 1'b1;
            end

            if (redirect || load_use || !ifid_valid) begin
                idex_valid <= 1'b0;
            end else begin
                idex_valid <= 1'b1;
                idex_pc <= ifid_pc;
                idex_pc4 <= ifid_pc4;
                idex_rd1 <= id_rd1_val;
                idex_rd2 <= id_rd2_val;
                idex_imm <= id_imm;
                idex_rs1 <= id_rs1;
                idex_rs2 <= id_rs2;
                idex_rd <= id_rd;
                idex_aluop <= id_aluop;
                idex_alusrc <= id_alusrc;
                idex_regwrite <= id_regwrite;
                idex_memwrite <= id_memwrite;
                idex_wdsel <= id_wdsel;
                idex_is_branch <= id_is_branch;
                idex_is_jal <= id_is_jal;
                idex_is_jalr <= id_is_jalr;
            end

            exmem_valid <= idex_valid;
            exmem_alu <= ex_alu;
            exmem_store <= fwd_b_raw;
            exmem_pc4 <= idex_pc4;
            exmem_rd <= idex_rd;
            exmem_regwrite <= idex_regwrite;
            exmem_memwrite <= idex_memwrite && !redirect;
            exmem_wdsel <= idex_wdsel;

            memwb_valid <= exmem_valid;
            memwb_alu <= exmem_alu;
            memwb_mem <= Data_in;
            memwb_pc4 <= exmem_pc4;
            memwb_rd <= exmem_rd;
            memwb_regwrite <= exmem_regwrite;
            memwb_wdsel <= exmem_wdsel;
        end
    end
endmodule


