// Serializes two 64 MS/s virtual ADC channels onto the board's one 14-bit bus.
module ad9248_emulator (
    input  logic               clk128,
    input  logic               clka,
    input  logic               clkb,
    input  logic signed [13:0] sample_a,
    input  logic signed [13:0] sample_b,
    output logic signed [13:0] data,
    output logic               otra,
    output logic               otrb
);
    logic select_b;
    initial begin
        select_b = 1'b0;
        data = '0;
        otra = 1'b0;
        otrb = 1'b0;
    end

    always @(posedge clk128) begin
        // CLKA/CLKB are the board clocks. Their complementary state selects
        // the interleaved sample slot; clk128 provides the PL data cadence.
        select_b <= clkb;
        data <= select_b ? sample_b : sample_a;
        otra <= 1'b0;
        otrb <= 1'b0;
    end
endmodule
