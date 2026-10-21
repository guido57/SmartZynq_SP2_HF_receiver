// Three-stage CIC section: decimation by 10, order 3, differential delay 1.
// The /1024 output scaling bounds every section while approximating its
// DC gain of 1000 (-0.21 dB per section).
module reference_cic_decimator #(
    parameter integer WIDTH = 30
) (
    input  logic                    clk,
    input  logic signed [WIDTH-1:0] in_i,
    input  logic signed [WIDTH-1:0] in_q,
    input  logic                    in_valid,
    output logic signed [WIDTH-1:0] out_i,
    output logic signed [WIDTH-1:0] out_q,
    output logic                    out_valid
);
    localparam integer ACC_W = WIDTH + 10;
    logic signed [ACC_W-1:0] integ_i [0:2];
    logic signed [ACC_W-1:0] integ_q [0:2];
    logic signed [ACC_W-1:0] delay_i [0:2];
    logic signed [ACC_W-1:0] delay_q [0:2];
    logic signed [ACC_W-1:0] comb0_i, comb1_i, comb2_i;
    logic signed [ACC_W-1:0] comb0_q, comb1_q, comb2_q;
    logic [3:0] count = '0;
    integer n;

    assign comb0_i = integ_i[2] - delay_i[0];
    assign comb1_i = comb0_i - delay_i[1];
    assign comb2_i = comb1_i - delay_i[2];
    assign comb0_q = integ_q[2] - delay_q[0];
    assign comb1_q = comb0_q - delay_q[1];
    assign comb2_q = comb1_q - delay_q[2];

    initial begin
        for (n = 0; n < 3; n = n + 1) begin
            integ_i[n] = '0;
            integ_q[n] = '0;
            delay_i[n] = '0;
            delay_q[n] = '0;
        end
        out_i = '0;
        out_q = '0;
        out_valid = 1'b0;
    end

    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (in_valid) begin
            integ_i[0] <= integ_i[0] + {{10{in_i[WIDTH-1]}}, in_i};
            integ_q[0] <= integ_q[0] + {{10{in_q[WIDTH-1]}}, in_q};
            integ_i[1] <= integ_i[1] + integ_i[0];
            integ_q[1] <= integ_q[1] + integ_q[0];
            integ_i[2] <= integ_i[2] + integ_i[1];
            integ_q[2] <= integ_q[2] + integ_q[1];

            if (count == 9) begin
                count <= '0;
                delay_i[0] <= integ_i[2];
                delay_i[1] <= comb0_i;
                delay_i[2] <= comb1_i;
                delay_q[0] <= integ_q[2];
                delay_q[1] <= comb0_q;
                delay_q[2] <= comb1_q;
                out_i <= comb2_i >>> 10;
                out_q <= comb2_q >>> 10;
                out_valid <= 1'b1;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule


// Single-channel complex DDC: 64 MS/s real input to 8 ksample/s complex I/Q.
// The module runs from clk128; sample_valid must pulse at the 64 MS/s rate.
module reference_ddc #(
    parameter integer FIR_DECIMATION = 8,
    parameter integer FIR_TAPS = 47
) (
    input  logic               clk128,
    input  logic signed [13:0] sample_in,
    input  logic               sample_valid,
`ifdef DDC_PHASE_INCREMENT_INPUT
    input  logic [47:0]        phase_increment_in,
`else
    input  logic [24:0]        vfo_hz,
`endif
    output logic signed [23:0] i_out,
    output logic signed [23:0] q_out,
    output logic               output_valid
);
    localparam integer MIX_W = 30;

    logic signed [15:0] sine_lut [0:255];
    logic signed [17:0] fir_coeff [0:FIR_TAPS-1];
    logic [47:0] nco_phase = '0;
    logic [47:0] nco_increment;
`ifndef DDC_PHASE_INCREMENT_INPUT
    logic [63:0] nco_khz_numerator;
    logic [63:0] nco_hz_numerator;
    logic [24:0] vfo_khz;
    logic [9:0] vfo_hz_remainder;
`endif
    logic signed [15:0] nco_sine;
    logic signed [15:0] nco_cosine;
    logic signed [MIX_W-1:0] mixer_product_i;
    logic signed [MIX_W-1:0] mixer_product_q;
    logic signed [MIX_W-1:0] mixed_i;
    logic signed [MIX_W-1:0] mixed_q;

    logic signed [MIX_W-1:0] cic1_i, cic1_q;
    logic signed [MIX_W-1:0] cic2_i, cic2_q;
    logic signed [MIX_W-1:0] cic3_i, cic3_q;
    logic cic1_valid, cic2_valid, cic3_valid;
    logic signed [31:0] cic_i;
    logic signed [31:0] cic_q;

    logic signed [31:0] fir_delay_i [0:FIR_TAPS-1];
    logic signed [31:0] fir_delay_q [0:FIR_TAPS-1];
    logic [2:0] fir_decimation_count = '0;
    logic [6:0] startup_count = '0;
    logic fir_busy = 1'b0;
    logic [5:0] fir_tap_index = '0;
    logic signed [57:0] fir_acc_i = '0;
    logic signed [57:0] fir_acc_q = '0;
    logic signed [49:0] fir_product_i;
    logic signed [49:0] fir_product_q;
    logic signed [49:0] fir_tap0_product_i;
    logic signed [49:0] fir_tap0_product_q;
    logic signed [49:0] fir_delay_i_ext;
    logic signed [49:0] fir_delay_q_ext;
    logic signed [49:0] fir_cic_i_ext;
    logic signed [49:0] fir_cic_q_ext;
    logic signed [49:0] fir_coeff_ext;
    logic signed [49:0] fir_coeff0_ext;
    logic signed [57:0] fir_product_i_ext;
    logic signed [57:0] fir_product_q_ext;
    logic signed [57:0] fir_tap0_product_i_ext;
    logic signed [57:0] fir_tap0_product_q_ext;
    logic signed [57:0] fir_sum_shifted_i;
    logic signed [57:0] fir_sum_shifted_q;

    function automatic logic signed [23:0] saturate_24(
        input logic signed [57:0] value
    );
        begin
            if (value[57:23] == {35{value[23]}})
                saturate_24 = value[23:0];
            else if (value[57])
                saturate_24 = 24'sh800000;
            else
                saturate_24 = 24'sh7fffff;
        end
    endfunction

    integer k;
    initial begin
        $readmemh("sine_lut.mem", sine_lut);
        $readmemh("ddc_fir_64k.mem", fir_coeff);
        for (k = 0; k < FIR_TAPS; k = k + 1) begin
            fir_delay_i[k] = '0;
            fir_delay_q[k] = '0;
        end
        i_out = '0;
        q_out = '0;
        output_valid = 1'b0;
    end

`ifdef DDC_PHASE_INCREMENT_INPUT
    // Benchmark/production option: software supplies round(f_hz * 2^48 / 64e6).
    assign nco_increment = phase_increment_in;
`else
    // Splitting Hz into kHz plus a remainder keeps both rounded products in
    // 64 bits while retaining 1 Hz VFO programming resolution.
    always_comb begin
        vfo_khz = vfo_hz / 1000;
        vfo_hz_remainder = vfo_hz % 1000;
        nco_khz_numerator = vfo_khz * 64'd281474976710656;
        nco_hz_numerator = vfo_hz_remainder * 64'd281474976710656;
        nco_increment = ((nco_khz_numerator + 64'd32000) / 64'd64000) +
                        ((nco_hz_numerator + 64'd32000000) / 64'd64000000);
    end
`endif

    assign nco_sine = sine_lut[nco_phase[47:40]];
    assign nco_cosine = sine_lut[nco_phase[47:40] + 8'd64];
    assign mixer_product_i = sample_in * nco_cosine;
    assign mixer_product_q = sample_in * nco_sine;
    assign mixed_i = mixer_product_i;
    assign mixed_q = -mixer_product_q;

    reference_cic_decimator #(.WIDTH(MIX_W)) cic_stage_1 (
        .clk(clk128), .in_i(mixed_i), .in_q(mixed_q), .in_valid(sample_valid),
        .out_i(cic1_i), .out_q(cic1_q), .out_valid(cic1_valid)
    );
    reference_cic_decimator #(.WIDTH(MIX_W)) cic_stage_2 (
        .clk(clk128), .in_i(cic1_i), .in_q(cic1_q), .in_valid(cic1_valid),
        .out_i(cic2_i), .out_q(cic2_q), .out_valid(cic2_valid)
    );
    reference_cic_decimator #(.WIDTH(MIX_W)) cic_stage_3 (
        .clk(clk128), .in_i(cic2_i), .in_q(cic2_q), .in_valid(cic2_valid),
        .out_i(cic3_i), .out_q(cic3_q), .out_valid(cic3_valid)
    );

    // Remove the Q1.15 sine-table scaling after the bounded CIC cascade.
    always_comb begin
        cic_i = $signed(cic3_i) >>> 15;
        cic_q = $signed(cic3_q) >>> 15;
    end

    assign fir_delay_i_ext = (fir_tap_index == 0) ? '0 :
                             {{18{fir_delay_i[fir_tap_index][31]}}, fir_delay_i[fir_tap_index]};
    assign fir_delay_q_ext = (fir_tap_index == 0) ? '0 :
                             {{18{fir_delay_q[fir_tap_index][31]}}, fir_delay_q[fir_tap_index]};
    assign fir_cic_i_ext = {{18{cic_i[31]}}, cic_i};
    assign fir_cic_q_ext = {{18{cic_q[31]}}, cic_q};
    assign fir_coeff_ext = (fir_tap_index == 0) ? '0 :
                           {{32{fir_coeff[fir_tap_index][17]}}, fir_coeff[fir_tap_index]};
    assign fir_coeff0_ext = {{32{fir_coeff[0][17]}}, fir_coeff[0]};
    assign fir_product_i = fir_delay_i_ext * fir_coeff_ext;
    assign fir_product_q = fir_delay_q_ext * fir_coeff_ext;
    assign fir_tap0_product_i = fir_cic_i_ext * fir_coeff0_ext;
    assign fir_tap0_product_q = fir_cic_q_ext * fir_coeff0_ext;
    assign fir_product_i_ext = {{8{fir_product_i[49]}}, fir_product_i};
    assign fir_product_q_ext = {{8{fir_product_q[49]}}, fir_product_q};
    assign fir_tap0_product_i_ext = {{8{fir_tap0_product_i[49]}}, fir_tap0_product_i};
    assign fir_tap0_product_q_ext = {{8{fir_tap0_product_q[49]}}, fir_tap0_product_q};
    assign fir_sum_shifted_i = (fir_acc_i + fir_product_i_ext) >>> 17;
    assign fir_sum_shifted_q = (fir_acc_q + fir_product_q_ext) >>> 17;

    always @(posedge clk128) begin
        output_valid <= 1'b0;
        if (sample_valid)
            nco_phase <= nco_phase + nco_increment;

        if (cic3_valid) begin
            for (k = FIR_TAPS-1; k > 0; k = k - 1) begin
                fir_delay_i[k] <= fir_delay_i[k-1];
                fir_delay_q[k] <= fir_delay_q[k-1];
            end
            fir_delay_i[0] <= cic_i;
            fir_delay_q[0] <= cic_q;

            if (startup_count < 64) begin
                startup_count <= startup_count + 1'b1;
                fir_decimation_count <= '0;
            end else if (fir_decimation_count == FIR_DECIMATION-1) begin
                fir_decimation_count <= '0;
                fir_acc_i <= fir_tap0_product_i_ext;
                fir_acc_q <= fir_tap0_product_q_ext;
                fir_tap_index <= 1;
                fir_busy <= 1'b1;
            end else begin
                fir_decimation_count <= fir_decimation_count + 1'b1;
            end
        end

        if (fir_busy) begin
            if (fir_tap_index == FIR_TAPS-1) begin
                fir_busy <= 1'b0;
                fir_tap_index <= '0;
                i_out <= saturate_24(fir_sum_shifted_i);
                q_out <= saturate_24(fir_sum_shifted_q);
                output_valid <= 1'b1;
            end else begin
                fir_acc_i <= fir_acc_i + fir_product_i_ext;
                fir_acc_q <= fir_acc_q + fir_product_q_ext;
                fir_tap_index <= fir_tap_index + 1'b1;
            end
        end
    end
endmodule
