`timescale 1ns/1ps

module data_memory_tb;
    reg clk;
    reg mem_write;
    reg [31:0] addr;
    reg [31:0] write_data;
    reg [2:0] load_sel;
    reg [2:0] store_sel;
    wire [31:0] read_data;

    data_memory uut (
        .clk(clk),
        .mem_write(mem_write),
        .addr(addr),
        .write_data(write_data),
        .load_sel(load_sel),
        .store_sel(store_sel),
        .read_data(read_data)
    );

    initial begin
        $dumpfile("mophong_vcd/data_memory_tb.vcd");
        $dumpvars(0, data_memory_tb);

        clk = 0; mem_write = 0; addr = 32'h0000_0000; write_data = 32'hA5A5_A5A5;
        store_sel = 3'b010; load_sel = 3'b010;

        // Write SW at address 0
        #5 addr = 32'h0000_0000; write_data = 32'h1234_5678; store_sel = 3'b010; mem_write = 1;
        #10 mem_write = 0;

        // Write SH at address 4
        #5 addr = 32'h0000_0004; write_data = 32'h0000_ABCD; store_sel = 3'b001; mem_write = 1;
        #10 mem_write = 0;

        // Write SB at address 8
        #5 addr = 32'h0000_0008; write_data = 32'h0000_00EF; store_sel = 3'b000; mem_write = 1;
        #10 mem_write = 0;

        // Test LW from address 0
        #5 addr = 32'h0000_0000; load_sel = 3'b010;
        #1 if (read_data !== 32'h1234_5678) $display("ERROR LW: got %h", read_data);

        // Test LH sign-extend from address 4
        #5 addr = 32'h0000_0004; load_sel = 3'b001;
        #1 if (read_data !== 32'hFFFF_ABCD) $display("ERROR LH: got %h", read_data);

        // Test LHU zero-extend from address 4
        #5 load_sel = 3'b101;
        #1 if (read_data !== 32'h0000_ABCD) $display("ERROR LHU: got %h", read_data);

        // Test LB sign-extend from address 8
        #5 addr = 32'h0000_0008; load_sel = 3'b000;
        #1 if (read_data !== 32'h0000_00EF) $display("ERROR LB: got %h", read_data);

        // Test LBU zero-extend from address 8
        #5 load_sel = 3'b100;
        #1 if (read_data !== 32'h0000_00EF) $display("ERROR LBU: got %h", read_data);

        $display("data_memory_tb finished");
        $finish;
    end

    always #5 clk = ~clk;
endmodule
