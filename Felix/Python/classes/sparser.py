class SNode:
    
    def __init__(self, root=None, children=None):
        self.root = root
        self.children = []
        if children is not None:
            for child in children:
                self.add_child(child)
    
    def __str__(self):
        return str(self.root)

    def __repr__(self):
        return str(self.root)

    def add_child(self, node):
        assert isinstance(node, SNode)
        if self.root is None:
            self.root = node
        else:
            self.children.append(node)
        return node
    
    def search(self, root): # This works for singleton keywords such as 'input' only. Otherwise, returns the first encountered.
        sexpr = None
        if str(self.root) == root:
            return self
        else:
            if not self.children:
                return None
            for child in self.children:
                sexpr = child.search(root)
                if sexpr is not None:
                    return sexpr

    def search_all(self, roots): # This works for layers that are present multiple times, such as 'fc'.
        sexprs = []
        if str(self.root) in roots:
            return [self]
        else:
            if not self.children:
                return None
            for child in self.children:
                sexpr=child.search_all(roots)
                if sexpr is not None:
                    sexprs.extend(sexpr)
            return sexprs

    def print(self):
        if not self.children:
            print("Argument:", self.root)
        else:
            print("Keyword:", self.root)
            for child in self.children:
                child.print()

    def all_str(self, level=0):
        if not self.children:
            return str(self.root)
        else:
            res = str(self.root) if level==0 else '('+str(self.root)
            for child in self.children:
                res+=" "+str(child.all_str(level + 1))
            return res if level==0 else res + ')' 
    def validate(self, verbose):
        if verbose:
            print("Validating", self.root)
        if str(self.root)=="nnet-codegen":
            if str(self.children[-1].root)=="network":
                self.children[-1].validate(verbose)
            else:
                print("WARNING: Expected 'network' as last top-level S-Expression but found", self.children[-1].root)
                print("For now, keragen only works with files containing a single network for training.")
        elif str(self.root)=="data":
            for datum in self.children:
                try:
                    if float(datum.root) != float(datum.root): #Check if NaN!=NaN, as defined
                        raise RuntimeError("Found non-number in S-Expression starting with 'data'.")
                except ValueError:
                    print("ERROR: Found non-number in S-Expression starting with 'data':", datum.root)
                    exit()
        elif str(self.root)=="network":
            for child in self.children:
                child.validate(verbose)
        elif str(self.root) in ["input", "output"]:
            try:
                #if int(str(self.children[0].root))>0:# and str(self.children[1].root)=="fixed":
                    #self.children[1].validate()
                if int(str(self.children[0].root))<=0:
                    print("ERROR: Negative or zero number of inputs/outputs found.")
                    exit()
                #else:
                    #print("ERROR: Unknown data representation used. Expected 'fixed', got '"+str(self.children[1].root)+"'.")
                    #exit()
            except ValueError:
                print("ERROR: Found non-integer as number of inputs/outputs:", str(self.children[0].root))
                exit()

        elif str(self.root)=="fc":
            output_defined = False
            neuron_defined = False
            index = 0
            for child in self.children:
                if (str(child.root)=="output"):
                    output_defined=True
                    self.children[index].validate(verbose)
                    
                if (str(child.root)=="neuron"):
                    neuron_defined=True
                    self.children[index].validate(verbose)
                    
                index += 1
            if (not output_defined):
                print("ERROR: No suitable output S-Expression found in 'fc' clause.")
                exit()
            if (not neuron_defined):
                print("ERROR: No suitable neuron S-Expression found in 'fc' clause.")
                exit()

        elif str(self.root)=="conv2d":
            output_defined = False
            neuron_defined = False
            kernel_defined = False
            stride_defined = False
            padding_defined = False
            index = 0
            for child in self.children:
                if (str(child.root)=="output"):
                    output_defined=True
                    self.children[index].validate(verbose)
                    
                if (str(child.root)=="neuron"):
                    neuron_defined=True
                    self.children[index].validate(verbose)

                if (str(child.root)=="kernel"):
                    kernel_defined=True
                    self.children[index].validate(verbose)
                    
                if (str(child.root)=="stride"):
                    stride_defined=True
                    self.children[index].validate(verbose)
                
                if (str(child.root)=="padding"):
                    padding_defined=True
                    self.children[index].validate(verbose)
                    
                index += 1
            if (not output_defined):
                print("ERROR: No suitable output S-Expression found in 'conv2d' clause.")
                exit()
            if (not neuron_defined):
                print("ERROR: No suitable neuron S-Expression found in 'conv2d' clause.")
                exit()
            if (not kernel_defined):
                print("ERROR: No suitable kernel S-Expression found in 'conv2d' clause.")
                exit()
            if (not stride_defined):
                print("ERROR: No suitable stride S-Expression found in 'conv2d' clause.")
                exit()
            if (not padding_defined):
                print("ERROR: No suitable padding S-Expression found in 'conv2d' clause.")
                exit()
        
        elif str(self.root)=="pool":
            type_defined = False
            stride_defined = False
            padding_defined = False
            index = 0
            for child in self.children:
                if (str(child.root) in ["max"]):
                    type_defined=True
                    self.children[index].validate(verbose)
                    
                if (str(child.root)=="stride"):
                    stride_defined=True
                    self.children[index].validate(verbose)
                
                if (str(child.root)=="padding"):
                    padding_defined=True
                    self.children[index].validate(verbose)
                    
                index += 1
            if (not type_defined):
                print("ERROR: No suitable pooling type S-Expression found in 'pool' clause.\nSupported types include : 'max'")
                exit()
            if (not stride_defined):
                print("ERROR: No suitable stride S-Expression found in 'pool' clause.")
                exit()
            if (not padding_defined):
                print("ERROR: No suitable padding S-Expression found in 'pool' clause.")
                exit()

        elif str(self.root)=="neuron":
            activation_defined = False
            index = 0
            for child in self.children:
                if (str(child.root) in ["sigmoid", "relu"]):
                    activation_defined=True
                    break
                index += 1
            if (not activation_defined):
                print("ERROR: No suitable activation function S-Expression found in 'neuron' clause.\nSupported activation functions include: 'sigmoid', 'relu'")
                exit()

        elif str(self.root) in ["kernel", "max", "stride"]:
            try:
                if int(str(self.children[0].root))<=0:
                    print("ERROR: Kernel, max and stride dimensions must be positive integers.")
                    exit()
            except ValueError:
                print("ERROR: Found non-integer as kernel, max or stride dimension:", str(self.children[0].root))
                exit()
        
        elif str(self.root) == "padding":
            if str(self.children[0].root) not in ["same", "valid"]:
                    print("ERROR: Unknown padding value encountered. Expected 'same' or 'valid', got '"+ str(self.children[0].root)+"'.")
                    exit()
        elif verbose:
            print("Network S-Expression is valid.")


class SParser:

    cursor = 0

    def __init__(self, filename):
        try:
            self.file = open(filename, 'r')
        except OSError:
            print("ERROR: Could not open specified file:", filename)
            exit()
        else:
            self.contents = self.file.read()
            self.file.close()

    def read_word(self, verbose):
        word = ""
        while (self.cursor < len(self.contents) and self.contents[self.cursor] not in ['(', ')'] and not self.contents[self.cursor].isspace()):
            word+=self.contents[self.cursor]
            self.cursor += 1
        if verbose:
            print("Parsed:", word)
        return word
    
    def read_quoted(self):
        word = ""
        while (self.cursor < len(self.contents) and self.contents[self.cursor] != '"'):
            if self.contents[self.cursor] == '\\':
                self.cursor += 1
            word+=self.contents[self.cursor]
            self.cursor += 1
        if self.cursor == len(self.contents):
            raise RuntimeError("Reached end of file before end of quote.", word)
        print("Parsed in quotes:", word)
        return word

    
    def parse(self, level=0, verbose=False):
        sexpr = SNode()
        while (self.cursor < len(self.contents) and self.contents[self.cursor] != ')'):
            if self.contents[self.cursor] == '(':
                self.cursor += 1
                if verbose:
                    print("New level of sexpr:", level + 1)
                sexpr.add_child(self.parse(level + 1))
                if verbose:
                    print ("Ended sexpr of level:", level + 1)
                    print("ROOT OF SEXPR:", str(sexpr.children[0].root))
                if str(sexpr.children[-1].root).strip() == "import":
                    if verbose:
                        print("FOUND IMPORT CLAUSE")
                    try:
                        imp = open(sexpr.children[-1].children[1].root, 'r').read()
                        #sexpr.replace(sexpr.children[-1].children[0].root, imp)
                        self.find_and_replace(sexpr.children[-1].children[0].root, imp, verbose)
                    except OSError:
                        print("ERROR: Could not open specified file:", sexpr.children[0].children[1].root)
                        exit()
                if str(sexpr.children[-1].root).strip() == "define":
                    if verbose:
                        print("FOUND DEFINE CLAUSE")
                    imp = sexpr.children[-1].children[1].all_str()#"data "+" ".join(map(str,sexpr.children[-1].children[1].children))
                    #sexpr.replace(sexpr.children[-1].children[0].root, imp)
                    self.find_and_replace(sexpr.children[-1].children[0].root, imp, verbose)
                
            elif self.contents[self.cursor] == '"':
                self.cursor += 1
                sexpr.add_child(SNode(self.read_quoted()))
            elif not self.contents[self.cursor].isspace():
                #Don't move cursor
                sexpr.add_child(SNode(self.read_word(verbose)))
                self.cursor -= 1
            
            self.cursor += 1

        if level != 0 and self.cursor >= len(self.contents):
            raise RuntimeError("Reached end of file before end of S-Expression.")
        elif level == 0 and self.cursor < len(self.contents):#self.contents[self.cursor]== ')':
            raise RuntimeError("Unexpected ')' encountered instead of end of file.")
            
        return sexpr
    
    def find_and_replace(self, identifier, content, verbose):
        #print("Cursor is at position:", self.cursor)
        #print("Last char read:", self.contents[self.cursor])
        newdata = self.contents[0:self.cursor] + self.contents[self.cursor:].replace("@"+identifier, content)
        newdata = newdata[0:self.cursor]+newdata[self.cursor:].replace("$"+identifier, "("+content+")")
        self.contents = newdata
        if verbose:
            print("Replaced " + identifier + " with " + content)

'''def main():
    spar = SParser("test.nn")
    
    spar.parse(0).print()

if __name__ == "__main__":
    main()

'''