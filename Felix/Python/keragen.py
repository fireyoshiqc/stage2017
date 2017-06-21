from classes.sparser import *
import sys, getopt

def main(argv):
    kerasfile=''
    trainvalid=''
    inputfile = None
    outputfile = None
    epochs=0
    batch_size=0
    try:
        opts, args = getopt.getopt(argv,"hi:o:", ["input=", "output="])
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
            outputfile = arg

    
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

    kerasfile += generate_layers(sexpr)
    kerasfile += create_training_loop()

    if outputfile is not None:
        print("Writing Keras code to", outputfile)
        out = open(outputfile, 'w+')
        out.write(kerasfile)
        out.close()
        print
        run_now = ''
        while run_now.upper() not in ['Y', 'N']:
            run_now=input("Do you want to train the model right now [Y/N]?")
            if run_now.upper() == 'N':
                print("The Keras model can be launched and trained from the "+ outputfile + " file.")
                exit()
            elif run_now.upper() == 'Y':
                print("Training Keras model dynamically...")
                exec(kerasfile)
            else:
                print("Please make a valid choice [Y/N].")
    else:
        print("No output file was defined. Training Keras model dynamically (use argument -o to write model to a file).")
        exec(kerasfile)
        exit()

    
    



def build_header():
    return """from __future__ import print_function
import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten
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
    x_train = x_train.reshape(x_train.shape[0], img_rows * img_cols)
    x_test = x_test.reshape(x_test.shape[0], img_rows * img_cols)
    input_shape = (1, img_rows * img_cols)
else:
    x_train = x_train.reshape(x_train.shape[0], img_rows * img_cols)
    x_test = x_test.reshape(x_test.shape[0], img_rows * img_cols)
    input_shape = (img_rows * img_cols, 1)

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

model = Sequential()
"""

def generate_layers(sexpr):
    assert isinstance(sexpr, SNode)
    print("Generating...", sexpr.root)
    layers=""
    input_shape = int(str(sexpr.search("input").children[0].root))
    fclayers = sexpr.search_all("fc")
    first_layer = True
    for layer in fclayers:
        output_size = int(str(layer.search("output").children[0]))
        activation_function = 'sigmoid' if layer.search("neuron").search("sigmoid") else 'relu'
        if first_layer:
            layers+="""model.add(Dense("""+str(output_size)+""", input_shape=("""+str(input_shape)+""",), activation='"""+activation_function+"""'))
"""
            first_layer=False
            print("Generated input FC layer with " + str(input_shape) + " inputs, " + str(output_size) + " neurons and a " + activation_function + " activation function.")
        else:
            layers+="""model.add(Dense("""+str(output_size)+""", activation='"""+activation_function+"""'))
"""
            print("Generated FC layer with " + str(output_size) + " neurons and a " + activation_function + " activation function.")

        
        dropout = -1.0
        
        while dropout < 0.0 or dropout > 1.0:
            try:
                dropout = float(input("Dropout of this FC layer for training [0.0-1.0]? Specify 0 for no dropout:"))
                if dropout < 0.0 or dropout > 1.0:
                    print("Please enter a dropout value in the range [0.0-1.0].")
            except ValueError:
                print("Please enter a valid real value (numbers).")
                continue
        
        if dropout == 0.0:
            print ("No dropout will be applied to this layer.")
        else:
            layers+="""model.add(Dropout("""+str(dropout)+"""))
"""
            print("Dropout of " + str(dropout) + " has been applied to this layer for training.")
    layers+="""model.add(Dense(num_classes, activation='softmax'))
""" #Only supports MNIST for now
    print("Done generating layers.")
    return layers

def create_training_loop():
    return """model.compile(loss=keras.losses.categorical_crossentropy, optimizer=keras.optimizers.Adadelta(), metrics=['accuracy'])

model.fit(x_train, y_train, batch_size=batch_size, epochs=epochs, verbose=1, validation_data=(x_test, y_test))

score = model.evaluate(x_test, y_test, verbose=0)
print('Test loss:', score[0])
print('Test accuracy:', score[1])
"""
if __name__ == "__main__":
    main(sys.argv[1:])


