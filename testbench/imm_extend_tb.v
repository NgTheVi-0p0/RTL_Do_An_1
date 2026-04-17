`timescale 1ns/1ps

module imm_extend_tb;
    reg [31:0] instr;
    reg [2:0] imm_sel;
    wire [31:0] imm_ext;

    imm_extend uut (
        .instr(instr),
        .imm_sel(imm_sel),
        .imm_ext(imm_ext)
    );

    initial begin
        $dumpfile("mophong_vcd/imm_extend_tb.vcd");
        $dumpvars(0, imm_extend_tb);

        // I-type: addi x1, x0, -1 -> imm = 0xFFF
        instr = 32'hFFF0_0093; imm_sel = 3'b000; #5;
        if (imm_ext !== 32'hFFFF_FFFF) $display("ERROR I-type: got %h", imm_ext);

        // S-type: sw x1, 4(x0) -> imm = 4
        instr = 32'h0000_0223; imm_sel = 3'b001; #5;
        if (imm_ext !== 32'h0000_0004) $display("ERROR S-type: got %h", imm_ext);

        // B-type: branch offset 8 -> imm = 8
        instr = 32'h0000_0463; imm_sel = 3'b010; #5;
        if (imm_ext !== 32'h0000_0008) $display("ERROR B-type: got %h", imm_ext);

        // U-type: lui x1, 0x12345 -> imm = 0x12345000
        instr = 32'h1234_50B7; imm_sel = 3'b011; #5;
        if (imm_ext !== 32'h1234_5000) $display("ERROR U-type: got %h", imm_ext);

        // J-type: jal x1, 2 -> imm = 2
        instr = 32'h0020_00EF; imm_sel = 3'b100; #5;
        if (imm_ext !== 32'h0000_0002) $display("ERROR J-type: got %h", imm_ext);

        $display("imm_extend_tb finished");
        $finish;
    end
endmodule
