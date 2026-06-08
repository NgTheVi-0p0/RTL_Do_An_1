module ALU (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0]  alu_ctrl, 
    output reg [31:0] result,
    output wire       zero
);
    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;                     // ADD
            4'b0001: result = a - b;                     // SUB
            4'b0010: result = a << b[4:0];               // SLL
            4'b0011: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT (Đảm bảo trả về đúng format 32-bit)
            4'b0100: result = (a < b) ? 32'd1 : 32'd0;   // SLTU
            4'b0101: result = a ^ b;                     // XOR
            4'b0110: result = a >> b[4:0];               // SRL
            4'b0111: result = $signed(a) >>> b[4:0];      // SRA
            4'b1000: result = a | b;                     // OR
            4'b1001: result = a & b;                     // AND
            4'b1010: result = b;                         // LUI: Lấy thẳng giá trị b (Immediate)
            default: result = 32'b0;
        endcase
    end
    
    assign zero = (result == 32'b0);
endmodule