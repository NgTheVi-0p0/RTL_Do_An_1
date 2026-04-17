`timescale 1ns/1ps

module Register_File_tb;
    reg clk;
    reg rst_n;
    reg reg_write;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg [4:0] rd;
    reg [31:0] wd;
    wire [31:0] rd1;
    wire [31:0] rd2;

    Register_File uut (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(wd),
        .rd1(rd1),
        .rd2(rd2)
    );

    initial begin
        $dumpfile("Register_File_tb.vcd");
        $dumpvars(0, Register_File_tb);

        clk = 0; rst_n = 0; reg_write = 0;
        rs1 = 5'd1; rs2 = 5'd2; rd = 5'd1; wd = 32'hDEAD_BEEF;
        #10 rst_n = 1;

        // Reset clears registers and x0 stays zero
        #10;
        if (rd1 !== 32'h0 || rd2 !== 32'h0) $display("ERROR RF reset: rd1=%h rd2=%h", rd1, rd2);

        // Write x1
        reg_write = 1; rd = 5'd1; wd = 32'h0000_1234; #10;
        rs1 = 5'd1; rs2 = 5'd0; #1;
        if (rd1 !== 32'h0000_1234) $display("ERROR RF write x1: got %h", rd1);
        if (rd2 !== 32'h0000_0000) $display("ERROR RF x0 read: expected 0 got %h", rd2);

        // Attempt to write x0 should not change x0
        reg_write = 1; rd = 5'd0; wd = 32'hFFFF_FFFF; #10;
        rs1 = 5'd0; rs2 = 5'd1; #1;
        if (rd1 !== 32'h0000_0000) $display("ERROR RF x0 write protection: got %h", rd1);
        if (rd2 !== 32'h0000_1234) $display("ERROR RF read x1 after x0 write: got %h", rd2);

        $display("Register_File_tb finished");
        $finish;
    end

    always #5 clk = ~clk;
endmodule
