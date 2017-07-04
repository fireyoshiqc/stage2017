import numpy as np
import math

int_input = [123, 45, 67, 89, 0, 123, 45, 67, 89]
fp_input = [float(x)/255.0 for x in int_input]
fp_weights = [0.0866466537117958, -0.21728886663913727, 0.07290978729724884,
0.011105816811323166, 0.034352757036685944,-0.032708484679460526,
0.011587132699787617, 0.008936501108109951, 0.008099686354398727]
fp_bias = 0.5
fp_all_biases = [fp_bias, -0.125152, 3.5215, 0.09823]

def quantize(bits, items):
        minval=None
        maxval=None
        for item in items:
            if minval is None:
                minval=item
            else:
                if item<minval:
                    minval=item
            if maxval is None:
                maxval=item
            else:
                if item>maxval:
                    maxval=item

        rangeval = maxval - minval
        bitrange = 2**bits - 1

        return ([int((item-minval) * bitrange / rangeval) for item in items], 255-int(maxval/rangeval * bitrange), rangeval, minval, maxval)

qtuple = quantize(8, fp_weights)
int_weights = qtuple[0]
zero_weights = qtuple[1]
adj_weights = [weight-zero_weights for weight in int_weights] #OP ON FPGA
print(zero_weights)
print(int_weights)
print(adj_weights)

max_xw = (1.0 * qtuple[4])*len(int_input)
min_xw = min(0, 1.0 * qtuple[3])*len(int_input)
zero_xw = (2**(16+math.ceil(math.log2(len(int_input))))-1)-int(max_xw/(max_xw-min_xw) * (2**(16+math.ceil(math.log2(len(int_input)))) - 1))#(np.dot(np.array(int_input), np.array([zero_weights, zero_weights, zero_weights, zero_weights]).T))
fzero_xw = float(zero_xw)/(2**(16+math.ceil(math.log2(len(int_input))))-1) * (max_xw-min_xw)+min_xw
bscale = fp_bias/(max_xw-min_xw)
int_bias = int((2**(16+math.ceil(math.log2(len(int_input)))) -1)*bscale)
step = (max_xw-min_xw)/(2**(16+math.ceil(math.log2(len(int_input)))))
#inv_bscale = max_xw/(fp_bias+max_xw)
#bscale = (fp_bias+max_xw)/max_xw
print("bscale  (float) : ", bscale)
print("max_xw  (float) : ", max_xw)
print("min_xw  (float) : ", min_xw)
print("zero_xw (fixed) : ", hex(zero_xw))
print("fzero_xw(fixed) : ", fzero_xw)
print("int_bias(fixed) : ", hex(int_bias))
print(math.ceil(math.log2(len(int_input))))

max_r = max_xw + fp_bias
min_r = min_xw + fp_bias
zero_r = max(0, (2**(16+math.ceil(math.log2(len(int_input))))-1)-int(max_r/(max_r-min_r) * (2**(16+math.ceil(math.log2(len(int_input)))) - 1)))#max(0,zero_xw)
fzero_r = float(zero_r)/(2**(16+math.ceil(math.log2(len(int_input))))-1) * (max_r-min_r)+min_r

print("max_r   (float) : ", max_r)
print("min_r   (float) : ", min_r)
print("zero_r  (fixed) : ", hex(zero_r))
print("fzero_r (fixed) : ", fzero_r)

fp_norelu = np.dot(np.array(fp_input), np.array(fp_weights).T) + fp_bias
q_norelu = int(np.dot(np.array(int_input), np.array(adj_weights).T)) + int_bias #OP ON FPGA
#qrelu = int_norelu

print("fp_norelu       : ", fp_norelu)
print("q_norelu        : ", hex(q_norelu))

fp_relu = 0.0 if fp_norelu < 0.0 else fp_norelu
q_relu = 0 if q_norelu < 0 else q_norelu
fpq_relu = float(q_relu)*step#(18+ math.log2(2**math.ceil(math.log2(fp_bias))) if fp_bias > 1 else 18)-1)*(max_r-min_r)+min_r
print("===========================================")
print("fp_relu  : ", fp_relu)
print("q_relu   : ", hex(q_relu))
print("fpq_relu   : ", fpq_relu)

rq_relu = q_relu >> (8+math.ceil(math.log2(len(int_input))))
fprq_relu = float(rq_relu)*step*(2**(8+math.ceil(math.log2(len(int_input)))))
print("rq_relu   : ", hex(rq_relu))
print("fprq_relu : ", fprq_relu)
print("DEVIATION : " + str(abs(float(fprq_relu-fp_relu))/(max_r-min_r)*100) + " %")




'''fp_norelu = np.dot(np.array(fp_input), np.array(fp_weights).T) + fp_bias
fp_relu = 0
if fp_norelu > 0:
    fp_relu = fp_norelu
print(fp_relu)
print(int_weights)
int_norelu = float(np.dot(np.array(int_input), np.array(int_weights).T)) / (2**16)
zero_relu = float(np.dot(np.array(int_input), np.array([zero_weights, zero_weights, zero_weights, zero_weights]).T)) / (2**16)

print(int_norelu)
print(zero_relu)

adj_bias = float(int(int_bias * bscale))/(2**16)
int_norelu_with_bias = int_norelu + adj_bias
zero_bias = float(int(zero_biases * bscale))/(2**16)
zero_relu_with_bias = zero_relu + zero_bias

print(int_norelu_with_bias)
print(zero_relu_with_bias)
print(int(int_norelu_with_bias*(2**8)))
print(int(zero_relu_with_bias*(2**8)))

max_out = qtuple[4]*1.0*4+btuple[4]
min_out = qtuple[3]*0.0*4+btuple[3]

print(max_out)
print(min_out)
print(min_out + 148.0/255.0 * max_out)
print(min_out + 53.0/255.0 * max_out)

'''

