// FT8 virtual RF source for the time-interleaved AD9248 emulator.
// Each output channel is updated at 64 MS/s from the common 128 MHz clock.
module ft8_virtual_rf_core #(
    parameter integer SYMBOL_SAMPLES = 10_240_000, // 160 ms at 64 MS/s
    parameter integer SLOT_SAMPLES   = 960_000_000 // 15 s at 64 MS/s
) (
    input  logic               clk128,
    input  logic               start_ft8,
    input  logic               stop_ft8,
    input  logic [14:0]        rf_freq_khz,
    // Packed FT8 symbols: ft8_symbols[3*n +: 3] is tone n, n = 0..78.
    input  logic [236:0]       ft8_symbols,
    output logic signed [13:0] sample_a,
    output logic signed [13:0] sample_b,
    output logic               source_active
);
    localparam integer SYMBOL_COUNT = 79;
    // round(6.25 Hz * 2^48 / 64 MHz). The resulting tone spacing is
    // 6.2500000695 Hz, an error of approximately 0.07 microhertz.
    localparam logic [47:0] TONE_PHASE_STEP = 48'd27487791;

    logic signed [15:0] sine_lut [0:255];
    logic [47:0] phase_a = '0;
    logic [47:0] phase_b = '0;
    logic [47:0] base_phase_increment;
    logic [47:0] phase_increment;
    logic [63:0] base_phase_numerator;
    logic [236:0] symbols_latched = '0;
    // Fixed production widths avoid module-reference parser ambiguity in IP Integrator.
    logic [29:0] slot_sample_count = '0;
    logic [23:0] symbol_sample_count = '0;
    logic [6:0] symbol_index = '0;
    logic [2:0] current_tone;
    logic channel_b = 1'b0;
    logic running = 1'b0;
    logic tx_active = 1'b0;
    logic signed [13:0] sample_a_reg = '0;
    logic signed [13:0] sample_b_reg = '0;

    initial $readmemh("sine_lut.mem", sine_lut);

    assign sample_a = sample_a_reg;
    assign sample_b = sample_b_reg;
    assign source_active = tx_active;
    assign current_tone = symbols_latched[(symbol_index * 3) +: 3];

    // round(rf_freq_khz * 1000 * 2^48 / 64e6)
    // = round(rf_freq_khz * 2^48 / 64000), for each 64 MS/s channel.
    always_comb begin
        base_phase_numerator = rf_freq_khz * 64'd281474976710656;
        base_phase_increment = (base_phase_numerator + 64'd32000) / 64'd64000;
        phase_increment = base_phase_increment + current_tone * TONE_PHASE_STEP;
    end

    always @(posedge clk128) begin
        if (stop_ft8) begin
            running             <= 1'b0;
            tx_active           <= 1'b0;
            channel_b           <= 1'b0;
            slot_sample_count   <= '0;
            symbol_sample_count <= '0;
            symbol_index        <= '0;
            phase_a             <= '0;
            phase_b             <= '0;
            sample_a_reg        <= '0;
            sample_b_reg        <= '0;
        end else if (!running) begin
            sample_a_reg <= '0;
            sample_b_reg <= '0;
            if (start_ft8) begin
                running             <= 1'b1;
                tx_active           <= 1'b1;
                channel_b           <= 1'b0;
                symbols_latched     <= ft8_symbols;
                slot_sample_count   <= '0;
                symbol_sample_count <= '0;
                symbol_index        <= '0;
                phase_a             <= '0;
                phase_b             <= '0;
            end
        end else begin
            channel_b <= ~channel_b;

            if (tx_active) begin
                if (channel_b) begin
                    phase_b      <= phase_b + phase_increment;
                    sample_b_reg <= sine_lut[phase_b[47:40]] >>> 2;
                end else begin
                    phase_a      <= phase_a + phase_increment;
                    sample_a_reg <= sine_lut[phase_a[47:40]] >>> 2;
                end
            end else begin
                sample_a_reg <= '0;
                sample_b_reg <= '0;
            end

            // One complete A/B pair is one 64 MS/s FT8 timebase tick.
            if (channel_b) begin
                if (slot_sample_count == SLOT_SAMPLES - 1) begin
                    // Repeat at the next 15-second boundary until STOP_FT8.
                    slot_sample_count   <= '0;
                    symbol_sample_count <= '0;
                    symbol_index        <= '0;
                    tx_active           <= 1'b1;
                    phase_a             <= '0;
                    phase_b             <= '0;
                end else begin
                    slot_sample_count <= slot_sample_count + 1'b1;

                    if (tx_active) begin
                        if (symbol_sample_count == SYMBOL_SAMPLES - 1) begin
                            symbol_sample_count <= '0;
                            if (symbol_index == SYMBOL_COUNT - 1) begin
                                tx_active <= 1'b0;
                            end else begin
                                symbol_index <= symbol_index + 1'b1;
                            end
                        end else begin
                            symbol_sample_count <= symbol_sample_count + 1'b1;
                        end
                    end
                end
            end
        end
    end
endmodule
