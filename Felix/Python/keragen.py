from classes.sparser import *
import sys, getopt

def main(argv):
    inputfile = ''
    outputfile = ''
    kerasfile=''
    trainvalid=''
    epochs=0
    batch_size=0
    try:
        opts, args = getopt.getopt(argv,"hi:o", ["input=", "output="])
    except getopt.GetoptError:
        print('keragen.py -i <input.nn file> -o <output.py file>')
        exit(2)
    for opt, arg in opts:
        if opt=='-h':
            print('keragen.py -i <input.nn file> -o <output.py file>')
            exit()
        elif opt in ("-i", "--input"):
            inputfile = arg
        elif opt in ("-o", "--output"):
            outputfil = arg

    
    sexpr = SParser(inputfile).parse()
    if str(sexpr.root) != "nnet-codegen":
        raise UserWarning("NN file should start with 'nnet-codegen'!")
    sexpr.print()
    sexpr.validate()

    kerasfile+=build_header()
    
    print("Please enter batch size and number of epochs for training...")
    while batch_size < 1:
        try:
            batch_size = int(input("Batch size: "))
            if batch_size < 1:
                print("Please enter a valid positive integer.")
        except ValueError:
            print("Please enter a valid positive integer.")
            continue
    while epochs < 1:
        try:
            epochs = int(input("Number of epochs: "))
            if epochs < 1:
                print("Please enter a valid positive integer.")
        except ValueError:
            print("Please enter a valid positive integer.")
            continue
    
    kerasfile += define_training_variables(batch_size, epochs)

    while trainvalid.upper() not in ['Y', 'N']:
        trainvalid=input("Since this is a training program, weights and biases entered in the .nn file will be ignored.\n"+
        "Is that okay? [Y/N]")
        if trainvalid.upper() == 'N':
            exit()
        elif trainvalid.upper() != 'Y':
            print("Please make a valid choice [Y/N].")

        
        
    print(kerasfile)



def build_header():
    return """from __future__ import print_function
import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense #, Dropout, Flatten
#from keras.layers import Conv2D, MaxPooling2D
from keras import backend as K

"""

#ONLY MNIST SUPPORTED FOR NOW
def define_training_variables(batch_size, epochs):
    return """batch_size = """+str(batch_size)+"""
epochs = """+str(epochs)+"""
num_classes = 10

# input image dimensions
img_rows, img_cols = 28, 28

# the data, shuffled and split between train and test sets
(x_train, y_train), (x_test, y_test) = mnist.load_data()

if K.image_data_format() == 'channels_first':
    x_train = x_train.reshape(x_train.shape[0], 1, img_rows, img_cols)
    x_test = x_test.reshape(x_test.shape[0], 1, img_rows, img_cols)
    input_shape = (1, img_rows, img_cols)
else:
    x_train = x_train.reshape(x_train.shape[0], img_rows, img_cols, 1)
    x_test = x_test.reshape(x_test.shape[0], img_rows, img_cols, 1)
    input_shape = (img_rows, img_cols, 1)

x_train = x_train.astype('float32')
x_test = x_test.astype('float32')
x_train /= 255
x_test /= 255
print('x_train shape:', x_train.shape)
print(x_train.shape[0], 'train samples')
print(x_test.shape[0], 'test samples')

# convert class vectors to binary class matrices
y_train = keras.utils.to_categorical(y_train, num_classes)
y_test = keras.utils.to_categorical(y_test, num_classes)
"""

if __name__ == "__main__":
    main(sys.argv[1:])


