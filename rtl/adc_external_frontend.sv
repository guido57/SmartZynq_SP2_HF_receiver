// Channel-A only: capture on the falling edge of its 8 MHz forwarded clock.
// The fixed ADC board emits offset binary: flip D13 before sign extension.
// Samples remain stable across the bundled-data CDC until the next ADC period.
module adc_external_frontend(
 input wire clk_adc, clk128, locked,
 input wire signed [13:0] adc_data,
 input wire adc_otra,
 output reg signed [13:0] sample=0,
 output reg valid=0,
 output reg overflow=0
);
 reg signed [13:0] held_data=0;
 reg held_overflow=0;
 reg toggle=0;
 always @(negedge clk_adc) begin
  if(!locked) begin held_data<=0;held_overflow<=0;toggle<=0;end
  else begin held_data<={~adc_data[13],adc_data[12:0]};held_overflow<=adc_otra;toggle<=~toggle;end
 end
 (* ASYNC_REG="TRUE" *) reg toggle_meta=0,toggle_sync=0;
 reg toggle_seen=0;
 always @(posedge clk128) begin
  toggle_meta<=toggle;toggle_sync<=toggle_meta;
  valid<=0;
  if(!locked)begin toggle_seen<=toggle_sync;sample<=0;overflow<=0;end
  else if(toggle_sync!=toggle_seen)begin
   sample<=held_data;overflow<=held_overflow;valid<=1;toggle_seen<=toggle_sync;
  end
 end
endmodule
