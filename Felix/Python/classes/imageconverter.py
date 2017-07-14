from mnist import MNIST

mndata = MNIST('samples')

images, labels = mndata.load_testing()

print(mndata.display(images[0]))

hexdata = [format(x, 'x') for x in images[0]]

file = open("imagedata_7.txt", "w+")

for item in hexdata:
  file.write("%s\n" % item)

file.close()

