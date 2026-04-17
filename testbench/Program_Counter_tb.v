`timescale 1ns/1ps

module Program_Counter_tb;
    reg clk;
    reg rst_n;
    reg start;
    reg stall;
    reg [31:0] pc_next;
    wire [31:0] pc_out;

    Program_Counter uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .stall(stall),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    initial begin
        $dumpfile("Program_Counter_tb.vcd");
        $dumpvars(0, Program_Counter_tb);

        clk = 0; rst_n = 0; start = 0; stall = 0; pc_next = 32'h0000_0004;
        #5 rst_n = 1;

        // start=0: pc should remain at reset value
        #10;
        if (pc_out !== 32'h0000_0000) $display("ERROR PC hold after reset: got %h", pc_out);

        start = 1;
        #10;
        if (pc_out !== 32'h0000_0004) $display("ERROR PC update when start=1: got %h", pc_out);

        stall = 1; pc_next = 32'h0000_0008;
        #10;
        if (pc_out !== 32'h0000_0004) $display("ERROR PC changed during stall: got %h", pc_out);

        stall = 0; #10;
        if (pc_out !== 32'h0000_0008) $display("ERROR PC update after stall: got %h", pc_out);

        $display("Program_Counter_tb finished");
        $finish;
    end

    always #5 clk = ~clk;
endmodule
