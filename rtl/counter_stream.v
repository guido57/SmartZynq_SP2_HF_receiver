// Standard-FIFO read timing: capture one word on each read-enable edge.
module counter_stream (
    input wire clk,
    input wire stream_open,
    input wire rden,
    output wire empty,
    output reg [31:0] data
);
    reg [31:0] next_word;
    assign empty = !stream_open;
    always @(posedge clk) begin
        if (!stream_open) begin
            next_word <= 0;
            data <= 0;
        end else if (rden) begin
            data <= next_word;
            next_word <= next_word + 1'b1;
        end
    end
endmodule
