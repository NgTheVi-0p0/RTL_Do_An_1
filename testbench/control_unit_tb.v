`timescale 1ns/1ps

module control_unit_tb;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    wire regWrite_D;
    wire [2:0] imm_sel;
    wire alu_srcA_D;
    wire alu_srcB_D;
    wire [9:0] alu_ctrl;
    wire branch_D;
    wire [2:0] bropcode;
    wire [1:0] jump_D;
    wire [2:0] load_sel_D;
    wire [2:0] store_sel_D;
    wire memWrite_D;
    wire [1:0] write_back_D;

    control_unit uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .regWrite_D(regWrite_D),
        .imm_sel(imm_sel),
        .alu_srcA_D(alu_srcA_D),
        .alu_srcB_D(alu_srcB_D),
        .alu_ctrl(alu_ctrl),
        .branch_D(branch_D),
        .bropcode(bropcode),
        .jump_D(jump_D),
        .load_sel_D(load_sel_D),
        .store_sel_D(store_sel_D),
        .memWrite_D(memWrite_D),
        .write_back_D(write_back_D)
    );

    task check;
        input [8*16-1:0] name;
        input [1:0] expect_wb;
        begin
            #5;
            if (write_back_D !== expect_wb) $display("ERROR %s: write_back_D=%b expected=%b", name, write_back_D, expect_wb);
            $display("%s: opcode=%b funct3=%b funct7=%b -> regWrite=%b branch=%b jump=%b alu_ctrl=%b", name, opcode, funct3, funct7, regWrite_D, branch_D, jump_D, alu_ctrl);
        end
    endtask

    initial begin
        $dumpfile("mophong_vcd/control_unit_tb.vcd");
        $dumpvars(0, control_unit_tb);

        opcode = 7'b0110111; funct3 = 3'b000; funct7 = 7'b0000000; // LUI
        check("LUI", 2'b00);

        opcode = 7'b0010111; check("AUIPC", 2'b00);

        opcode = 7'b1101111; check("JAL", 2'b10);

        opcode = 7'b1100111; funct3 = 3'b000; funct7 = 7'b0000000; check("JALR", 2'b10);

        opcode = 7'b1100011; funct3 = 3'b000; check("BEQ", 2'b00);

        opcode = 7'b0000011; funct3 = 3'b010; check("LW", 2'b01);

        opcode = 7'b0100011; funct3 = 3'b010; check("SW", 2'b00);

        opcode = 7'b0010011; funct3 = 3'b000; funct7 = 7'b0000000; check("ADDI", 2'b00);

        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0000000; check("ADD", 2'b00);
        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0100000; check("SUB", 2'b00);

        $display("control_unit_tb finished");
        $finish;
    end
endmodule
