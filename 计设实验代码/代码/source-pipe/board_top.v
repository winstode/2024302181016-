module board_top(
    input         clk,
    input         rstn,
    input  [15:0] sw_i,
    output [15:0] led_o,
    output [7:0]  disp_seg_o,
    output [7:0]  disp_an_o
);
    wire [31:0] reg_data;
    wire [31:0] pc_debug;
    wire [31:0] sid_original;
    wire [31:0] sid_sorted;
    wire [31:0] display_data;
    wire        cpu_reset;
    wire        cpu_clk;
    reg  [16:0] cpu_div;

    assign cpu_reset = ~rstn;

    always @(posedge clk or posedge cpu_reset) begin
        if (cpu_reset)
            cpu_div <= 17'd0;
        else
            cpu_div <= cpu_div + 17'd1;
    end

    BUFG U_CPU_BUFG(
        .I(cpu_div[16]),
        .O(cpu_clk)
    );

    pipecomp U_PIPECOMP(
        .clk(cpu_clk),
        .rstn(cpu_reset),
        .reg_sel(sw_i[8:4]),
        .reg_data(reg_data),
        .pc_debug(pc_debug),
        .sid_original(sid_original),
        .sid_sorted(sid_sorted)
    );

    assign display_data =
        (sw_i[1:0] == 2'b00) ? sid_sorted :
        (sw_i[1:0] == 2'b01) ? sid_original :
        (sw_i[1:0] == 2'b10) ? pc_debug :
                                reg_data;

    assign led_o[15]   = (sid_sorted == 32'h0011_1268);
    assign led_o[14]   = (sid_original == 32'h0218_1016);
    assign led_o[13:8] = pc_debug[7:2];
    assign led_o[7:0]  = display_data[7:0];

    seg7_hex U_SEG7(
        .clk(clk),
        .rst(cpu_reset),
        .data(display_data),
        .seg(disp_seg_o),
        .an(disp_an_o)
    );
endmodule

`ifdef __ICARUS__
module BUFG(input I, output O);
    assign O = I;
endmodule
`endif

module seg7_hex(
    input         clk,
    input         rst,
    input  [31:0] data,
    output reg [7:0] seg,
    output reg [7:0] an
);
    reg [16:0] refresh_cnt;
    wire [2:0] digit_sel;
    reg [3:0] hex;

    assign digit_sel = refresh_cnt[16:14];

    always @(posedge clk or posedge rst) begin
        if (rst)
            refresh_cnt <= 17'd0;
        else
            refresh_cnt <= refresh_cnt + 17'd1;
    end

    always @(*) begin
        an = 8'b1111_1111;
        an[digit_sel] = 1'b0;

        case (digit_sel)
        3'd0: hex = data[3:0];
        3'd1: hex = data[7:4];
        3'd2: hex = data[11:8];
        3'd3: hex = data[15:12];
        3'd4: hex = data[19:16];
        3'd5: hex = data[23:20];
        3'd6: hex = data[27:24];
        3'd7: hex = data[31:28];
        default: hex = 4'h0;
        endcase

        case (hex)
        4'h0: seg = 8'b1100_0000;
        4'h1: seg = 8'b1111_1001;
        4'h2: seg = 8'b1010_0100;
        4'h3: seg = 8'b1011_0000;
        4'h4: seg = 8'b1001_1001;
        4'h5: seg = 8'b1001_0010;
        4'h6: seg = 8'b1000_0010;
        4'h7: seg = 8'b1111_1000;
        4'h8: seg = 8'b1000_0000;
        4'h9: seg = 8'b1001_0000;
        4'ha: seg = 8'b1000_1000;
        4'hb: seg = 8'b1000_0011;
        4'hc: seg = 8'b1100_0110;
        4'hd: seg = 8'b1010_0001;
        4'he: seg = 8'b1000_0110;
        4'hf: seg = 8'b1000_1110;
        default: seg = 8'b1111_1111;
        endcase
    end
endmodule

