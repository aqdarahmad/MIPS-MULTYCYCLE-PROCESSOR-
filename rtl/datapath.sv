// ============================================================
// Datapath - Multi-Cycle MIPS Processor
// ============================================================
module datapath (
    input  logic        clk, reset,
    // Control signals from Control Unit
    input  logic        PCWrite, PCWriteControl,
    input  logic        IorD, MemRead, MemWrite,
    input  logic        IRWrite, MemtoReg,
    input  logic        RegWrite, RegDst,
    input  logic        ALUSelA, TargetWrite,
    input  logic [1:0]  ALUSelB, PCSrc, ALUOp,
    // Output signals to Control Unit
    output logic [5:0]  opc, fn,
    output logic        Zero
);

    // ──────────────────────────────────────
    // Internal Wires
    // ──────────────────────────────────────
    logic [31:0] PC, PC_next;
    logic [31:0] MemAddr;
    logic [31:0] MemDataOut;
    logic [31:0] IR;
    logic [31:0] MemDataReg;   // Memory Data Register (MDR)

    logic [4:0]  rs, rt, rd, wreg;
    logic [15:0] imm;
    logic [25:0] immJ;
    logic [31:0] SignExtImm, ShiftedImm, ShiftedJ;

    logic [31:0] RegDataA, RegDataB;  // $rs, $rt outputs
    logic [31:0] wdata;

    logic [31:0] ALU_A, ALU_B;
    logic [31:0] ALUResult;
    logic [31:0] Target;

    logic [3:0]  ALUControl;
    logic        PCEnable;

    // ──────────────────────────────────────
    // 1. PC Register
    // ──────────────────────────────────────
    assign PCEnable = PCWrite | (PCWriteControl & Zero);

    always_ff @(posedge clk or posedge reset) begin
        if (reset)         PC <= 32'h0000_0000;
        else if (PCEnable) PC <= PC_next;
    end

    // ──────────────────────────────────────
    // 2. MUX (IorD) - Memory Address Select
    //    0: PC (instruction fetch)
    //    1: ALUResult (load/store address)
    // ──────────────────────────────────────
    assign MemAddr = IorD ? ALUResult : PC;

    // ──────────────────────────────────────
    // 3. Shared Memory (Instructions + Data)
    // ──────────────────────────────────────
    memory MEM (
        .clk     (clk),
        .MemRead (MemRead),
        .MemWrite(MemWrite),
        .address (MemAddr),
        .wdata   (RegDataB),   // $rt for Store instructions
        .rdata   (MemDataOut)
    );

    // ──────────────────────────────────────
    // 4. Instruction Register (IR)
    // ──────────────────────────────────────
    always_ff @(posedge clk) begin
        if (IRWrite) IR <= MemDataOut;
    end

    // MDR - saves the data read from memory
    always_ff @(posedge clk) begin
        MemDataReg <= MemDataOut;
    end

    // ──────────────────────────────────────
    // 5. Instruction Field Extraction
    // ──────────────────────────────────────
    assign opc  = IR[31:26];
    assign rs   = IR[25:21];
    assign rt   = IR[20:16];
    assign rd   = IR[15:11];
    assign fn   = IR[5:0];
    assign imm  = IR[15:0];
    assign immJ = IR[25:0];

    // ──────────────────────────────────────
    // 6. MUX wreg: rd (R-Type) or rt (I-Type)
    // ──────────────────────────────────────
    assign wreg = RegDst ? rd : rt;

    // ──────────────────────────────────────
    // 7. MUX wdata: ALUResult or MDR
    // ──────────────────────────────────────
    assign wdata = MemtoReg ? MemDataReg : ALUResult;

    // ──────────────────────────────────────
    // 8. Register File
    // ──────────────────────────────────────
    register_file RF (
        .clk     (clk),
        .RegWrite(RegWrite),
        .rreg1   (rs),
        .rreg2   (rt),
        .wreg    (wreg),
        .wdata   (wdata),
        .rdata1  (RegDataA),   // $rs output
        .rdata2  (RegDataB)    // $rt output
    );

    // ──────────────────────────────────────
    // 9. Sign Extend + Shift Left 2
    // ──────────────────────────────────────
    assign SignExtImm = {{16{imm[15]}}, imm};       // 16-bit to 32-bit sign extended
    assign ShiftedImm = {SignExtImm[29:0], 2'b00};  // multiply by 4 for Branch offset
    assign ShiftedJ   = {6'b000000, immJ, 2'b00};   // multiply by 4 for Jump address

    // ──────────────────────────────────────
    // 10. MUX ALU_A (ALUSelA)
    //     0: PC  |  1: $rs
    // ──────────────────────────────────────
    assign ALU_A = ALUSelA ? RegDataA : PC;

    // ──────────────────────────────────────
    // 11. MUX ALU_B (ALUSelB) - 4 options
    // ──────────────────────────────────────
    always_comb begin
        case (ALUSelB)
            2'b00: ALU_B = RegDataB;    // $rt
            2'b01: ALU_B = 32'd4;       // constant 4 for PC+4
            2'b10: ALU_B = SignExtImm;  // I-Type immediate
            2'b11: ALU_B = ShiftedImm;  // Branch offset (shifted left 2)
        endcase
    end

    // ──────────────────────────────────────
    // 12. ALU Control
    // ──────────────────────────────────────
    alu_control ALU_CTRL (
        .ALUOp     (ALUOp),
        .fn        (fn),
        .ALUControl(ALUControl)
    );

    // ──────────────────────────────────────
    // 13. ALU
    // ──────────────────────────────────────
    alu ALU_UNIT (
        .A         (ALU_A),
        .B         (ALU_B),
        .ALUControl(ALUControl),
        .Result    (ALUResult),
        .Zero      (Zero)
    );

    // ──────────────────────────────────────
    // 14. Target Register (holds Jump address)
    // ──────────────────────────────────────
    always_ff @(posedge clk) begin
        if (TargetWrite) Target <= ShiftedJ;
    end

    // ──────────────────────────────────────
    // 15. MUX PC_next (PCSrc) - 4 options
    // ──────────────────────────────────────
    always_comb begin
        case (PCSrc)
            2'b00: PC_next = ALUResult;  // normal: PC + 4
            2'b01: PC_next = ALUResult;  // branch target address
            2'b10: PC_next = Target;     // jump address
            2'b11: PC_next = RegDataA;   // jump register ($rs)
        endcase
    end

endmodule