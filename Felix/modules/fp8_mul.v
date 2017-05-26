module fp8_mul(clk, ina, inb, out);
input clk;
input [7:0] ina;
input [7:0] inb;
output [7:0] out;

reg [4:0] expsum;
reg [7:0] fractionres;
reg sign;

always @(posedge clk) begin

    expsum <= ina[6:3] + inb[6:3] - 14;
    fractionres <= {1'b1, ina[2:0]} * {1'b1, inb[2:0]}
    if (fractionres[7] !== 0)
        expsum <= expsum + 1;
    sign <= ina[7] ^ inb[7];
    out <= {sign, expsum[3:0], fractionres[7:5]}

end


