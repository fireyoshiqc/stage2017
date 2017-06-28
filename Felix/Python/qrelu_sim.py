import numpy as np
import math

int_input = [250, 25, 75, 100]
fp_input = [250.0/255.0, 25.0/255.0, 75.0/255.0, 100.0/255.0]
fp_weights = [0.0525123580, -0.0519875112, 0.09812585192, 0.063464388346]
fp_bias = 5
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
print(zero_weights)
print(int_weights)

max_xw = (1.0 * qtuple[4])*4
min_xw = min(0, 1.0 * qtuple[3])*4
zero_xw = (np.dot(np.array(int_input), np.array([zero_weights, zero_weights, zero_weights, zero_weights]).T))
zm_xw = (4*255*255)
zr_xw = float(zero_xw)/float(zm_xw)
int_bias = int((2**18 -1)*fp_bias/(max_xw-min_xw))
#inv_bscale = max_xw/(fp_bias+max_xw)
#bscale = (fp_bias+max_xw)/max_xw

print("max_xw  (float) : ", max_xw)
print("min_xw  (float) : ", min_xw)
print("zr_xw   (fixed) : ", zr_xw)
print("int_bias(fixed) : ", int_bias)

max_r = max_xw + fp_bias
min_r = min_xw + fp_bias
zero_r = max(0,zero_xw-int_bias)

print("max_r   (float) : ", max_r)
print("min_r   (float) : ", min_r)
print("zero_r  (fixed) : ", hex(zero_r))

fp_norelu = np.dot(np.array(fp_input), np.array(fp_weights).T) + fp_bias
q_norelu = int(np.dot(np.array(int_input), np.array(int_weights).T))
#qrelu = int_norelu

print("fp_norelu       : ", fp_norelu)
print("q_norelu        : ", hex(q_norelu))

fp_relu = 0.0 if fp_norelu < 0.0 else fp_norelu
q_relu = zero_r if q_norelu < zero_r else q_norelu
fpq_relu = float(q_relu)/(2**(18 + math.log2(2**math.ceil(math.log2(fp_bias))) if fp_bias > 1 else 18))*(max_r-min_r)+min_r
print("===========================================")
print("fp_relu  : ", fp_relu)
print("q_relu   : ", hex(q_relu))
print("fpq_relu   : ", fpq_relu)



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

