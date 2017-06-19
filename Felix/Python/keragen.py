from classes.sparser import *

sexpr = SParser("test.nn").parse()
if str(sexpr.root) != "nnet-codegen":
    raise UserWarning("NN file should start with 'nnet-codegen'!")
