from __future__ import print_function
import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten
from keras.layers import Conv2D, MaxPooling2D
from keras import backend as K

batch_size = 100
epochs = 40
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

model = Sequential()
model.add(Conv2D(10, padding='same', kernel_size=(3,3), strides=(1,1), input_shape=(28, 28, 1), activation='relu'))
model.add(MaxPooling2D(padding='valid', pool_size=(2,2), strides=(2,2)))
model.add(Dropout(0.2))
model.add(Conv2D(10, padding='same', kernel_size=(5,5), strides=(1,1), activation='relu'))
model.add(MaxPooling2D(padding='valid', pool_size=(2,2), strides=(2,2)))
model.add(Dropout(0.35))
model.add(Flatten())
model.add(Dense(40, activation='relu'))
model.add(Dropout(0.5))
model.add(Dense(num_classes, activation='softmax'))
model.compile(loss=keras.losses.categorical_crossentropy, optimizer=keras.optimizers.Adadelta(), metrics=['accuracy'])

model.fit(x_train, y_train, batch_size=batch_size, epochs=epochs, verbose=1, validation_data=(x_test, y_test))

score = model.evaluate(x_test, y_test, verbose=0)
print('Test loss:', score[0])
print('Test accuracy:', score[1])

counter = 0
for layer in model.layers:
    if layer.get_weights():
        saver = open('convtest_w'+str(counter)+'.nn', 'w+')
        saver.write(" ".join(map(str,layer.get_weights()[0].flatten().tolist())))
        saver.close()
        print('Saved weights for layer', str(counter))
        saver = open('convtest_b'+str(counter)+'.nn', 'w+')
        saver.write(" ".join(map(str,layer.get_weights()[1].flatten().tolist())))
        saver.close()
        print('Saved biases for layer', str(counter))
        counter += 1

print('Weights and biases all saved.\nThe last saved layer is a softmax layer; its weights can be ignored if not using softmax in the FPGA implementation.')
