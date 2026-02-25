// ============================================================
// Testbench - Multi-Cycle Processor
// ============================================================
`timescale 1ns/1ps

module testbench;

    logic clk, reset;

    // ────────────────────────────
    // Instantiate the Processor
    // ────────────────────────────
    top DUT (
        .clk   (clk),
        .reset (reset)
    );

    // ────────────────────────────
    // Clock: period = 10ns
    // ────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ────────────────────────────
    // Test Program loaded into memory:
    //   addi $t0, $0, 5     -> $t0 = 5
    //   addi $t1, $0, 3     -> $t1 = 3
    //   add  $t2, $t0, $t1  -> $t2 = 8
    //   sw   $t2, 0($0)     -> Memory[0] = 8
    //   lw   $t3, 0($0)     -> $t3 = 8
    //   beq  $t0, $t0, end  -> branch taken
    // ────────────────────────────
    initial begin
        // Load instructions directly into memory
        DUT.DP.MEM.mem[0] = 32'h20080005; // addi $t0, $0, 5
        DUT.DP.MEM.mem[1] = 32'h20090003; // addi $t1, $0, 3
        DUT.DP.MEM.mem[2] = 32'h01095020; // add  $t2, $t0, $t1
        DUT.DP.MEM.mem[3] = 32'hAC0A0000; // sw   $t2, 0($0)
        DUT.DP.MEM.mem[4] = 32'h8C0B0000; // lw   $t3, 0($0)
        DUT.DP.MEM.mem[5] = 32'h11080000; // beq  $t0, $t0, +0
    end

    // ────────────────────────────
    // Reset then run
    // ────────────────────────────
    initial begin
        reset = 1;
        repeat(2) @(posedge clk);
        reset = 0;

        // Wait enough cycles for the program to finish
        repeat(50) @(posedge clk);

        // ────────────────────────────
        // Check Results
        // ────────────────────────────
        $display("==============================");
        $display("       Test Results           ");
        $display("==============================");
        $display("$t0 (reg  8) = %0d  (expected 5)", DUT.DP.RF.registers[8]);
        $display("$t1 (reg  9) = %0d  (expected 3)", DUT.DP.RF.registers[9]);
        $display("$t2 (reg 10) = %0d  (expected 8)", DUT.DP.RF.registers[10]);
        $display("$t3 (reg 11) = %0d  (expected 8)", DUT.DP.RF.registers[11]);
        $display("Memory[0]   = %0d  (expected 8)", DUT.DP.MEM.mem[0]);
        $display("==============================");

        if (DUT.DP.RF.registers[10] == 32'd8)
            $display("PASS: Result is correct!");
        else
            $display("FAIL: Result is wrong!");

        $finish;
    end

    // ────────────────────────────
    // Dump waveform for GTKWave
    // ────────────────────────────
    initial begin
        $shm_open("waves.shm");   // Cadence format
        $shm_probe(testbench, "AS");
        $shm_close;
    end

endmodule