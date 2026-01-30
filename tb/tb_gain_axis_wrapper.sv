`timescale 1ns / 1ps
// ============================================================================
// Testbench  : tb_axis_gain_wrapper
// Description: AXI-Stream + AXI-Lite system-level testbench
//              - Stereo sine-wave stimulus
//              - Gain control via AXI-Lite
//              - CSV logging for offline analysis
// ============================================================================

module tb_axis_gain_wrapper;

    // ------------------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------------------
    localparam integer CLK_PERIOD = 10;   // 100 MHz
    localparam integer FBITS      = 12;   // Q4.12
    localparam real    PI         = 3.141592653589793;

    // ------------------------------------------------------------------------
    // Clocks & reset
    // ------------------------------------------------------------------------
    reg aclk;
    reg aresetn;

    // ------------------------------------------------------------------------
    // AXI-Stream (Input)
    // ------------------------------------------------------------------------
    reg  [31:0] s_axis_tdata;
    reg         s_axis_tlast;
    reg         s_axis_tvalid;
    wire        s_axis_tready;

    // ------------------------------------------------------------------------
    // AXI-Stream (Output)
    // ------------------------------------------------------------------------
    wire [31:0] m_axis_tdata;
    wire        m_axis_tlast;
    wire        m_axis_tvalid;
    reg         m_axis_tready;

    // ------------------------------------------------------------------------
    // AXI-Lite (Write only)
    // ------------------------------------------------------------------------
    reg  [3:0]  s_axi_awaddr;
    reg         s_axi_awvalid;
    wire        s_axi_awready;
    reg  [31:0] s_axi_wdata;
    reg  [3:0]  s_axi_wstrb;
    reg         s_axi_wvalid;
    wire        s_axi_wready;
    wire [1:0]  s_axi_bresp;
    wire        s_axi_bvalid;
    reg         s_axi_bready;

    // Unused read channel (tied off)
    reg  [3:0]  s_axi_araddr  = 0;
    reg         s_axi_arvalid = 0;
    reg         s_axi_rready  = 0;

    // ------------------------------------------------------------------------
    // Monitoring & stimulus helpers
    // ------------------------------------------------------------------------
    integer f_out;
    integer i;
    real    theta;

    reg signed [15:0] sine_sample;
    reg signed [15:0] input_l, input_r;
    wire signed [15:0] output_l, output_r;

    reg [64*8:1] test_case_name;

    // ------------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------------
    axis_gain_wrapper #(
        .AUDIO_WIDTH(16),
        .GAIN_FBITS (FBITS)
    ) dut (
        .aclk           (aclk),
        .aresetn        (aresetn),

        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tlast   (s_axis_tlast),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),

        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tlast   (m_axis_tlast),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),

        .s_axi_awaddr   (s_axi_awaddr),
        .s_axi_awvalid  (s_axi_awvalid),
        .s_axi_awready  (s_axi_awready),
        .s_axi_wdata    (s_axi_wdata),
        .s_axi_wstrb    (s_axi_wstrb),
        .s_axi_wvalid   (s_axi_wvalid),
        .s_axi_wready   (s_axi_wready),
        .s_axi_bresp    (s_axi_bresp),
        .s_axi_bvalid   (s_axi_bvalid),
        .s_axi_bready   (s_axi_bready),

        .s_axi_araddr   (s_axi_araddr),
        .s_axi_arvalid  (s_axi_arvalid),
        .s_axi_arready  (),
        .s_axi_rdata    (),
        .s_axi_rresp    (),
        .s_axi_rvalid   (),
        .s_axi_rready   (s_axi_rready)
    );

    assign output_l = m_axis_tdata[15:0];
    assign output_r = m_axis_tdata[31:16];

    // ------------------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------------------
    initial begin
        aclk = 1'b0;
        forever #(CLK_PERIOD/2) aclk = ~aclk;
    end

    // ------------------------------------------------------------------------
    // AXI-Lite write task
    // ------------------------------------------------------------------------
    task write_reg(input [3:0] addr, input [31:0] data);
    begin
        @(posedge aclk);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1'b1;
        s_axi_wdata   <= data;
        s_axi_wvalid  <= 1'b1;
        s_axi_wstrb   <= 4'hF;
        s_axi_bready  <= 1'b1;

        wait (s_axi_awready && s_axi_wready);
        @(posedge aclk);
        s_axi_awvalid <= 1'b0;
        s_axi_wvalid  <= 1'b0;

        wait (s_axi_bvalid);
        @(posedge aclk);
        s_axi_bready <= 1'b0;

        $display("AXI-Lite WRITE: addr=0x%h data=0x%h", addr, data);
    end
    endtask

    // ------------------------------------------------------------------------
    // AXI-Stream stimulus: one sine period
    // ------------------------------------------------------------------------
    task send_sine_wave(input integer num_samples);
    begin
        for (i = 0; i < num_samples; i = i + 1) begin
            theta = 2.0 * PI * i / num_samples;
            sine_sample = $rtoi(16000.0 * $sin(theta));

            input_l =  sine_sample;
            input_r = -sine_sample;

            s_axis_tvalid <= 1'b1;
            s_axis_tdata  <= {input_r, input_l};
            s_axis_tlast  <= (i == num_samples-1);

            while (!s_axis_tready)
                @(posedge aclk);

            @(posedge aclk);
        end

        s_axis_tvalid <= 1'b0;
        s_axis_tlast  <= 1'b0;
        repeat (2) @(posedge aclk);
    end
    endtask

    // ------------------------------------------------------------------------
    // CSV logger
    // ------------------------------------------------------------------------
    initial begin
        f_out = $fopen("gain_simulation_axis.csv", "w");
        $fwrite(f_out, "Time_ns,Case,In_L,In_R,Out_L,Out_R\n");
    end

    always @(posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            $fwrite(f_out, "%0t,%s,%d,%d,%d,%d\n",
                    $time, test_case_name,
                    $signed(s_axis_tdata[15:0]),
                    $signed(s_axis_tdata[31:16]),
                    output_l, output_r);
        end
    end

    // ------------------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------------------
    initial begin
        aresetn        = 1'b0;
        s_axis_tvalid  = 1'b0;
        s_axis_tlast   = 1'b0;
        m_axis_tready  = 1'b1;
        s_axi_awvalid  = 1'b0;
        s_axi_wvalid   = 1'b0;
        s_axi_bready   = 1'b0;

        repeat (2) @(posedge aclk);
        aresetn = 1'b1;
        repeat (2) @(posedge aclk);

        // ------------------------------------------------------------
        // Case 1: Bypass
        // ------------------------------------------------------------
        test_case_name = "BYPASS";
        write_reg(4'h0, 32'h0000_0000);
        send_sine_wave(36);

        // ------------------------------------------------------------
        // Case 2: Gain = 1.0
        // ------------------------------------------------------------
        test_case_name = "GAIN_1.0";
        write_reg(4'h4, 32'h0000_1000);
        write_reg(4'h8, 32'h0000_1000);
        write_reg(4'h0, 32'h0000_0001);
        send_sine_wave(36);

        // ------------------------------------------------------------
        // Case 3: Gain = 0.5
        // ------------------------------------------------------------
        test_case_name = "GAIN_0.5";
        write_reg(4'h4, 32'h0000_0800);
        write_reg(4'h8, 32'h0000_0800);
        send_sine_wave(36);

        // ------------------------------------------------------------
        // Case 4: Gain = 2.5 (saturation)
        // ------------------------------------------------------------
        test_case_name = "GAIN_2.5_SAT";
        write_reg(4'h4, 32'h0000_2800);
        write_reg(4'h8, 32'h0000_2800);
        send_sine_wave(36);

        $fclose(f_out);
        $display("Simulation finished. CSV saved.");
        $stop;
    end

endmodule
