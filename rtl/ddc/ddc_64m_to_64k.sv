// Three-stage CIC section: decimation by 10, order 3, differential delay 1.
// The /1024 output scaling bounds every section while approximating its
// DC gain of 1000 (-0.21 dB per section).
module cic_decimator_10_n3 #(
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
    logic signed [ACC_W-1:0] comb_stage0_i=0,comb_stage0_q=0;
    logic signed [ACC_W-1:0] comb_stage1_i=0,comb_stage1_q=0;
    logic comb_valid0=0,comb_valid1=0;
    logic [3:0] count = '0;
    integer n;

    assign comb0_i = integ_i[2] - delay_i[0];
    assign comb1_i = comb_stage0_i - delay_i[1];
    assign comb2_i = comb_stage1_i - delay_i[2];
    assign comb0_q = integ_q[2] - delay_q[0];
    assign comb1_q = comb_stage0_q - delay_q[1];
    assign comb2_q = comb_stage1_q - delay_q[2];

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
        comb_valid0<=0;comb_valid1<=comb_valid0;out_valid<=comb_valid1;
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
                comb_stage0_i<=comb0_i;
                delay_q[0] <= integ_q[2];
                comb_stage0_q<=comb0_q;
                comb_valid0<=1;
            end else begin
                count <= count + 1'b1;
            end
        end
        // One subtract per clock, preserving the original modulo arithmetic.
        if(comb_valid0)begin
            comb_stage1_i<=comb1_i;comb_stage1_q<=comb1_q;
            delay_i[1]<=comb_stage0_i;delay_q[1]<=comb_stage0_q;
        end
        if(comb_valid1)begin
            out_i<=comb2_i >>> 10;out_q<=comb2_q >>> 10;
            delay_i[2]<=comb_stage1_i;delay_q[2]<=comb_stage1_q;
        end
    end
endmodule


// Per-channel mixer/NCO and CIC front end: 64 MS/s real to 64 ksample/s I/Q.
// The module runs from clk128; sample_valid must pulse at the 64 MS/s rate.
module ddc_64m_to_64k (
    input  logic               clk128,
    input  logic signed [13:0] sample_in,
    input  logic               sample_valid,
`ifdef DDC_PHASE_INCREMENT_INPUT
    input  logic [47:0]        phase_increment_in,
`else
    input  logic [24:0]        vfo_hz,
`endif
    output wire signed [31:0] i_out,
    output wire signed [31:0] q_out,
    output wire                output_valid
);
    localparam integer MIX_W = 30;

    logic signed [15:0] sine_lut [0:255];
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

    logic mixed_valid=0;
    initial $readmemh("sine_lut.mem",sine_lut);
    always @(posedge clk128) if(sample_valid)nco_phase<=nco_phase+nco_increment;
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
    initial begin mixed_i=0;mixed_q=0;end
    always @(posedge clk128) begin
        mixed_valid<=sample_valid;
        if(sample_valid)begin mixed_i<=mixer_product_i;mixed_q<=-mixer_product_q;end
    end

    cic_decimator_10_n3 #(.WIDTH(MIX_W)) cic_stage_1 (
        .clk(clk128), .in_i(mixed_i), .in_q(mixed_q), .in_valid(mixed_valid),
        .out_i(cic1_i), .out_q(cic1_q), .out_valid(cic1_valid)
    );
    cic_decimator_10_n3 #(.WIDTH(MIX_W)) cic_stage_2 (
        .clk(clk128), .in_i(cic1_i), .in_q(cic1_q), .in_valid(cic1_valid),
        .out_i(cic2_i), .out_q(cic2_q), .out_valid(cic2_valid)
    );
    cic_decimator_10_n3 #(.WIDTH(MIX_W)) cic_stage_3 (
        .clk(clk128), .in_i(cic2_i), .in_q(cic2_q), .in_valid(cic2_valid),
        .out_i(cic3_i), .out_q(cic3_q), .out_valid(cic3_valid)
    );

    // Remove the Q1.15 sine-table scaling after the bounded CIC cascade.
    always_comb begin
        cic_i = $signed(cic3_i) >>> 15;
        cic_q = $signed(cic3_q) >>> 15;
    end

    assign i_out=cic_i;
    assign q_out=cic_q;
    assign output_valid=cic3_valid;
endmodule
