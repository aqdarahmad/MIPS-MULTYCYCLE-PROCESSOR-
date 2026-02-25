// ============================================================
// ALU Control
// ============================================================
module alu_control (
    input  logic [1:0] ALUOp,
    input  logic [5:0] fn,
    output logic [3:0] ALUControl
);
    // ALUOp encoding:
    // 00 -> ADD  (Fetch, MemAddr stages)
    // 01 -> SUB  (Branch comparison)
    // 10 -> R-Type (fn field decides operation)

    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 4'b0010; // ADD
            2'b01: ALUControl = 4'b0110; // SUB
            2'b10: begin
                case (fn)
                    6'b100000: ALUControl = 4'b0010; // ADD
                    6'b100010: ALUControl = 4'b0110; // SUB
                    6'b100100: ALUControl = 4'b0000; // AND
                    6'b100101: ALUControl = 4'b0001; // OR
                    6'b101010: ALUControl = 4'b0111; // SLT
                    default:   ALUControl = 4'b0010;
                endcase
            end
            default: ALUControl = 4'b0010;
        endcase
    end
endmodule


// ============================================================
// ALU - Arithmetic Logic Unit
// ============================================================
module alu (
    input  logic [31:0] A, B,
    input  logic [3:0]  ALUControl,
    output logic [31:0] Result,
    output logic        Zero
);
    always_comb begin
        case (ALUControl)
            4'b0000: Result = A & B;                    // AND
            4'b0001: Result = A | B;                    // OR
            4'b0010: Result = A + B;                    // ADD
            4'b0110: Result = A - B;                    // SUB
            4'b0111: Result = (A < B) ? 32'd1 : 32'd0; // SLT
            4'b1100: Result = ~(A | B);                 // NOR
            default: Result = 32'd0;
        endcase
    end

    assign Zero = (Result == 32'd0);
endmodule


// ============================================================
// Register File (32 registers x 32-bit)
// ============================================================
module register_file (
    input  logic        clk,
    input  logic        RegWrite,
    input  logic [4:0]  rreg1, rreg2, wreg,
    input  logic [31:0] wdata,
    output logic [31:0] rdata1, rdata2
);
    logic [31:0] registers [0:31];

    // $zero is always 0
    assign registers[0] = 32'd0;

    // Asynchronous read (combinational)
    assign rdata1 = (rreg1 == 5'd0) ? 32'd0 : registers[rreg1];
    assign rdata2 = (rreg2 == 5'd0) ? 32'd0 : registers[rreg2];

    // Synchronous write on rising clock edge
    always_ff @(posedge clk) begin
        if (RegWrite && wreg != 5'd0)
            registers[wreg] <= wdata;
    end
endmodule


// ============================================================
// Shared Memory (Instructions + Data)
// 256 words x 32-bit = 1KB
// ============================================================
module memory (
    input  logic        clk,
    input  logic        MemRead, MemWrite,
    input  logic [31:0] address, wdata,
    output logic [31:0] rdata
);
    logic [31:0] mem [0:255];

    // Load program from hex file at simulation start
    initial begin
        $readmemh("program.hex", mem);
    end

    // Asynchronous read
    assign rdata = MemRead ? mem[address[9:2]] : 32'd0;

    // Synchronous write on rising clock edge
    always_ff @(posedge clk) begin
        if (MemWrite)
            mem[address[9:2]] <= wdata;
    end
endmodule