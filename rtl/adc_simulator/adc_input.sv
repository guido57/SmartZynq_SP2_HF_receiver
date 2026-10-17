// Common input front end for the physical AD9248 and virtual RF source.
module adc_input (
    input  logic               clk128,
    input  logic               select_virtual,
    input  logic signed [13:0] adc_data,
    input  logic               adc_otra,
    input  logic               adc_otrb,
    input  logic signed [13:0] virtual_data,
    input  logic               virtual_otra,
    input  logic               virtual_otrb,
    output logic               clka,
    output logic               clkb,
    output logic signed [13:0] ddc_sample_a,
    output logic signed [13:0] ddc_sample_b,
    output logic               ddc_valid_a,
    output logic               ddc_valid_b,
    output logic               otra,
    output logic               otrb
);
    logic select_b;
    logic signed [13:0] selected_data;

    always_comb begin
        selected_data = select_virtual ? virtual_data : adc_data;
        otra = select_virtual ? virtual_otra : adc_otra;
        otrb = select_virtual ? virtual_otrb : adc_otrb;
    end

    initial begin
        clka = 1'b0; clkb = 1'b1; select_b = 1'b0;
        ddc_sample_a = '0; ddc_sample_b = '0;
        ddc_valid_a = 1'b0; ddc_valid_b = 1'b0;
    end

    always @(posedge clk128) begin
        clka <= ~clka;
        clkb <= ~clkb;
        select_b <= ~select_b;
        ddc_valid_a <= 1'b0;
        ddc_valid_b <= 1'b0;
        if (select_b) begin
            ddc_sample_b <= selected_data;
            ddc_valid_b <= 1'b1;
        end else begin
            ddc_sample_a <= selected_data;
            ddc_valid_a <= 1'b1;
        end
    end
endmodule
