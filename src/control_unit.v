module control_unit (
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7, 

    output reg        regWrite_D,   
    output reg [2:0]  imm_sel,      
    output reg        alu_srcA_D,   
    output reg        alu_srcB_D,   
    output reg [3:0]  alu_ctrl,     
    output reg        branch_D,     
    output reg [2:0]  bropcode,     
    output reg [1:0]  jump_D,       // 01: JAL, 10: JALR, 00: No Jump
    output reg [2:0]  load_sel_D,   
    output reg [2:0]  store_sel_D,  // ĐÃ SỬA: Xóa dấu & lỗi cú pháp ở đây
    output reg        memWrite_D,   
    output reg [1:0]  write_back_D, 
    output reg        uses_rs1_D,   
    output reg        uses_rs2_D    
);

    // Định nghĩa hằng số ALU 4-bit mã hóa
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010;
    localparam ALU_SLT  = 4'b0011;
    localparam ALU_SLTU = 4'b0100;
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;
    localparam ALU_LUI  = 4'b1010; 

    always @(*) begin
        // --- Giá trị mặc định tránh tạo chốt lật (Latch generation) ---
        regWrite_D   = 0; 
        imm_sel      = 3'b000; 
        alu_srcA_D   = 0; 
        alu_srcB_D   = 0;
        alu_ctrl     = ALU_ADD; 
        branch_D     = 0; 
        bropcode     = 3'b000; 
        jump_D       = 2'b00;
        load_sel_D   = 3'b010; 
        store_sel_D  = 3'b010; 
        memWrite_D   = 0; 
        write_back_D = 2'b00;
        uses_rs1_D   = 1'b0; 
        uses_rs2_D   = 1'b0;

        case (opcode)
            // 1. LUI
            7'b0110111: begin
                regWrite_D   = 1; 
                imm_sel      = 3'b011; 
                alu_srcB_D   = 1;
                alu_ctrl     = ALU_LUI; 
                write_back_D = 2'b00;
            end

            // 2. AUIPC
            7'b0010111: begin
                regWrite_D   = 1; 
                imm_sel      = 3'b011; 
                alu_srcA_D   = 1; 
                alu_srcB_D   = 1;
                alu_ctrl     = ALU_ADD; 
                write_back_D = 2'b00;
            end

            // 3. JAL
            7'b1101111: begin
                regWrite_D   = 1; 
                imm_sel      = 3'b100; 
                jump_D       = 2'b01; // Đánh dấu lệnh JAL nhảy không điều kiện
                write_back_D = 2'b10; 
            end

            // 4. JALR
            7'b1100111: begin
                regWrite_D   = 1; 
                imm_sel      = 3'b000; 
                jump_D       = 2'b10; // Đánh dấu lệnh JALR
                alu_srcB_D   = 1; 
                alu_ctrl     = ALU_ADD; 
                write_back_D = 2'b10;
                uses_rs1_D   = 1'b1;
            end

            // 5. BRANCH (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            7'b1100011: begin
                branch_D   = 1; 
                imm_sel    = 3'b010; 
                bropcode   = funct3; // Đưa thẳng funct3 ra để phân loại kiểu so sánh nhánh
                alu_ctrl   = (funct3[2:1] == 2'b11) ? ALU_SLTU : ALU_SUB; 
                uses_rs1_D = 1'b1; 
                uses_rs2_D = 1'b1;
            end

            // 6. LOAD
            7'b0000011: begin
                regWrite_D   = 1; 
                imm_sel      = 3'b000; 
                alu_srcB_D   = 1;
                alu_ctrl     = ALU_ADD; 
                load_sel_D   = funct3; 
                write_back_D = 2'b01;
                uses_rs1_D   = 1'b1;
            end

            // 7. STORE
            7'b0100011: begin
                memWrite_D  = 1; 
                imm_sel     = 3'b001; 
                alu_srcB_D  = 1;
                alu_ctrl    = ALU_ADD; 
                store_sel_D = funct3;
                uses_rs1_D  = 1'b1; 
                uses_rs2_D  = 1'b1;
            end

            // 8. I-Type ALU
            7'b0010011: begin
                regWrite_D = 1; 
                alu_srcB_D = 1; 
                imm_sel    = 3'b000;
                uses_rs1_D = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b101: alu_ctrl = (funct7[5]) ? ALU_SRA : ALU_SRL;
                endcase
            end

            // 9. R-Type ALU
            7'b0110011: begin
                regWrite_D = 1; 
                alu_srcB_D = 0;
                uses_rs1_D = 1'b1; 
                uses_rs2_D = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = (funct7[5]) ? ALU_SUB : ALU_ADD;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                endcase
            end
            default: ;
        endcase
    end
endmodule