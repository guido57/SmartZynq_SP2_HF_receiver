// Derives complementary 64 MHz ADC clocks from the 128 MHz PL clock.
module ad9248_clock_gen (
    input  logic clk128,
    output logic clka,
    output logic clkb
);
    initial begin
        clka = 1'b0;
        clkb = 1'b1;
    end

    always @(posedge clk128) begin
        clka <= ~clka;
        clkb <= ~clkb;
    end
endmodule
