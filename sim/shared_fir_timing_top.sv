// Register-boundary harness: measure internal core timing, not unconstrained
// external pin skew. Boundary registers are excluded from core utilization.
module shared_fir_timing_top(
 input wire clk,in_valid,
 input wire [2:0] in_channel,
 input wire signed [31:0] in_i,in_q,
 output reg out_valid,overrun,
 output reg [2:0] out_channel,
 output reg signed [23:0] out_i,out_q
);
 reg valid_r=0;reg[2:0] channel_r=0;reg signed[31:0] i_r=0,q_r=0;
 wire valid_w,fault_w;wire[2:0] channel_w;wire signed[23:0] i_w,q_w;
 always @(posedge clk)begin
  valid_r<=in_valid;channel_r<=in_channel;i_r<=in_i;q_r<=in_q;
  out_valid<=valid_w;out_channel<=channel_w;out_i<=i_w;out_q<=q_w;overrun<=fault_w;
 end
 (* keep_hierarchy="yes" *) shared_fir_decimator filter(.clk(clk),.in_valid(valid_r),
 .in_channel(channel_r),.in_i(i_r),.in_q(q_r),.out_valid(valid_w),
 .out_channel(channel_w),.out_i(i_w),.out_q(q_w),.overrun(fault_w));
endmodule
