class Quantizer:
    
    def __init__(self):
        print("Quantizer initialized")

    def file_to_array(self, filename):
        file = open(filename, 'r')
        items = list(map(float, file.read().split(" ")))
        return items
    
    def quantize(self, bits, items):
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

        return [int((item-minval) * bitrange / rangeval) for item in items]

    def array_to_file(self, filename, items):
        file = open(filename, 'w+')
        file.write(" ".join(list(map(str, items))))
        file.close()

