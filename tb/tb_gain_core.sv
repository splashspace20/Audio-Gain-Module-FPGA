`timescale 1ns / 1ps
// ============================================================================
// Testbench  : tb_gain_core
// Description: Directed unit test for gain_core
//              - Fixed-point gain verification
//              - Saturation behavior
//              - Bypass and clock-enable behavior
//
// Output     : CSV log for offline analysis and plotting
// ============================================================================

module tb_gain_core;

    // ------------------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------------------
    localparam integer DWIDTH     = 16;
    localparam integer GWIDTH     = 16;
    localparam integer FBITS      = 12; // Q4.12 format
    localparam integer CLK_PERIOD = 10;

    // ------------------------------------------------------------------------
    // Signals
    // ------------------------------------------------------------------------
    reg clk;
    reg rst_n;
    reg ce;
    reg en;
    reg signed [DWIDTH-1:0] data_i;
    reg signed [GWIDTH-1:0] data_gain;
    wire signed [DWIDTH-1:0] data_o;

    // CSV file handle
    integer f_out;

    // ------------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------------
    gain_core #(
        .DWIDTH(DWIDTH),
        .GWIDTH(GWIDTH),
        .FBITS (FBITS)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .ce        (ce),
        .en        (en),
        .data_i    (data_i),
        .data_gain (data_gain),
        .data_o    (data_o)
    );

    // ------------------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ------------------------------------------------------------------------
    // Fixed-point gain constants (Q4.12)
    // ------------------------------------------------------------------------
    localparam signed [15:0] GAIN_1_0 = 16'd4096; // 1.0
    localparam signed [15:0] GAIN_0_5 = 16'd2048; // 0.5
    localparam signed [15:0] GAIN_2_0 = 16'd8192; // 2.0

    // ------------------------------------------------------------------------
    // CSV logger
    // ------------------------------------------------------------------------
    initial begin
        f_out = $fopen("gain_core_results.csv", "w");
        $fwrite(f_out, "Time_ns,Reset,CE,Enable,Input,Gain,Output\n");
    end

    always @(posedge clk) begin
        if (rst_n) begin
            $fwrite(f_out, "%0t,%b,%b,%b,%d,%d,%d\n",
                    $time, rst_n, ce, en,
                    $signed(data_i), $signed(data_gain), $signed(data_o));
        end
    end

    // ------------------------------------------------------------------------
    // Check task
    // ------------------------------------------------------------------------
    task check_output(input signed [15:0] expected, input string msg);
    begin
        #1; // allow data to settle
        if (data_o !== expected) begin
            $display("[ERROR] %s | exp=%d got=%d",
                     msg, expected, data_o);
        end else begin
            $display("[PASS ] %s | out=%d", msg, data_o);
        end
    end
    endtask

    // ------------------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------------------
    initial begin
        // Init
        rst_n     = 1'b0;
        ce        = 1'b0;
        en        = 1'b0;
        data_i   = '0;
        data_gain= GAIN_1_0;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        ce    = 1'b1;

        $display("=======================================");
        $display("START UNIT TEST: gain_core");
        $display("=======================================");

        // Test 1: Bypass
        en       = 1'b0;
        data_i  = 16'd1234;
        data_gain = GAIN_2_0;
        @(posedge clk);
        check_output(16'd1234, "Bypass");

        // Test 2: Unity gain
        en       = 1'b1;
        data_i  = 16'd1000;
        data_gain = GAIN_1_0;
        @(posedge clk);
        check_output(16'd1000, "Unity gain");

        // Test 3: Attenuation
        data_i  = 16'd5000;
        data_gain = GAIN_0_5;
        @(posedge clk);
        check_output(16'd2500, "Attenuation");

        // Test 4: Amplify (safe)
        data_i  = 16'd10000;
        data_gain = GAIN_2_0;
        @(posedge clk);
        check_output(16'd20000, "Amplify safe");

        // Test 5: Positive saturation
        data_i  = 16'd20000;
        data_gain = GAIN_2_0;
        @(posedge clk);
        check_output(16'd32767, "Positive saturation");

        // Test 6: Negative saturation
        data_i  = -16'd20000;
        data_gain = GAIN_2_0;
        @(posedge clk);
        check_output(-16'd32768, "Negative saturation");

        // Test 7: Mute
        data_i  = -16'd12345;
        data_gain = 16'd0;
        @(posedge clk);
        check_output(16'd0, "Mute");

        // Test 8: Clock enable hold
        data_i = 16'd100;
        data_gain = GAIN_1_0;
        ce = 1'b0;
        @(posedge clk);
        check_output(16'd0, "CE hold");

        ce = 1'b1;
        @(posedge clk);
        check_output(16'd100, "CE resume");

        $display("=======================================");
        $display("TEST FINISHED");
        $display("=======================================");

        $fclose(f_out);
        $stop;
    end

endmodule
