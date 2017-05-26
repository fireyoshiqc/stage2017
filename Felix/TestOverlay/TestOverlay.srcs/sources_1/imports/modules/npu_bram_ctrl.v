module npu_bram_ctrl(
addr,
clk,
din,
dout,
drd,
dwr,
rden,
offset,
rst,
wren
);

parameter RD_BITS = 32;

output [31:0] addr;
input clk;
input [RD_BITS-1:0] din;
output [RD_BITS-1:0] dout;
input [RD_BITS-1:0] drd;
output [31:0] dwr;
input rden;
input [31:0] offset;
input rst;
output [3:0] wren;

reg [RD_BITS-1:0] dout = {RD_BITS{1'b0}};
reg [31:0] dwr = 0;
reg [3:0] wren = 4'b0000;
reg [31:0] addr = 0;
wire [31:0] offset;

//assign address = offset;


always @ (posedge clk) begin
//    wren <= 4'b1111;
//    dwr <= 1;
//    addr <= addr + 4;
    if (rst == 1) begin
        if (rden == 1) begin
            wren <= 4'b0000;
            dout <= drd;
        end
        else begin
            wren <= 4'b1111;
            dwr <= din;
        end
    end
    else begin
        wren <= 4'b0000;
        dout <= 0;
        dwr <= 0;
    end
end
endmodule


