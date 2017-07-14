import math

filename = input("Which NN file do you want to convert to fixed point?\n")
file = open(filename, "r")
print("Reading file, this may take a while...")
values = [float(i) for i in file.read().split(" ")]
file.close()
minimum = min(values)
maximum = max(values)
bits = 0
signed = 0
print("Minimum value is :", minimum)
if (float(minimum) < 0):
    print("This value is below zero, adding sign bit.")
    bits += 1
    signed = 1


print("Maximum value is :", maximum)
intpart = max(math.modf(abs(minimum))[1],math.modf(maximum)[1])
intbits = 0 if intpart==0 else math.ceil(math.log2(intpart))

bits += intbits

print("Integer part requires at least " + str(bits) + " bit(s) (sign included).")
decbits = int(input("How many bits do you want to use for the decimal part?\n"))
bits += decbits
file = open(filename.strip(".nn")+(".txt"), "w+")
bitstring = ""
for value in values :
    bitstring=""
    cnt = bits-signed
    while (cnt> 0):
        reduced = abs(value) - 2**(cnt-decbits-1)

        if (reduced > 0):
            value = reduced
            bitstring+="1"
        else:
            bitstring+="0"
        cnt -= 1

    
    if (value < 0):
        bitstring.replace("0", "a").replace("1","0").replace("a", "1")

    if(signed > 0):
        bitstring = "0" + bitstring if value >= 0 else "1" + bitstring
    
    ures = int(bitstring, 2)

    if(value < 0):
        ures += 1

    

    hexdata = format(ures, 'x')

    file.write("%s\n" % hexdata)
file.close()



    