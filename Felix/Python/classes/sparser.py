class SNode:
    
    def __init__(self, root=None, children=None):
        self.root = root
        self.children = []
        if children is not None:
            for child in children:
                self.add_child(child)
    
    def __repr__(self):
        return self.root

    def add_child(self, node):
        assert isinstance(node, SNode)
        if self.root is None:
            self.root = node
        else:
            self.children.append(node)
        return node
    
    def print(self):
        if not self.children:
            print("Argument:", self.root)
        else:
            print("Keyword:", self.root)
            for child in self.children:
                child.print()

class SParser:

    cursor = 0

    def __init__(self, filename):
        try:
            self.file = open(filename, 'r')
        except OSError:
            print("Could not open specified file:", filename)
            exit()
        else:
            self.contents = self.file.read()
            self.file.close()

    def read_word(self):
        word = ""
        while (self.cursor < len(self.contents) and self.contents[self.cursor] not in ['(', ')'] and not self.contents[self.cursor].isspace()):
            word+=self.contents[self.cursor]
            self.cursor += 1
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

    
    def parse(self, level=0):
        sexpr = SNode()
        while (self.cursor < len(self.contents) and self.contents[self.cursor] != ')'):
            if self.contents[self.cursor] == '(':
                self.cursor += 1
                print("New level of sexpr:", level + 1)
                sexpr.add_child(self.parse(level + 1))
                print ("Ended sexpr of level:", level + 1)
                if sexpr.root == "import":
                    imp = open(sexpr.children[1].root, 'r')
                    self.find_and_replace(sexpr.children[0].root, imp)
            elif self.contents[self.cursor] == '"':
                self.cursor += 1
                sexpr.add_child(SNode(self.read_quoted()))
            elif not self.contents[self.cursor].isspace():
                #Don't move cursor
                sexpr.add_child(SNode(self.read_word()))
                self.cursor -= 1
            
            self.cursor += 1

        if level != 0 and self.cursor >= len(self.contents):
            raise RuntimeError("Reached end of file before end of S-Expression.")
        elif level == 0 and self.cursor < len(self.contents):#self.contents[self.cursor]== ')':
            raise RuntimeError("Unexpected ')' encountered instead of end of file.")
            
        return sexpr
    
    def find_and_replace(self, identifier, content):
        newdata = self.contents[self.contents.find(identifier):].replace(identifier, content)
        if identifier[0]=='$':
            #With parentheses
            self.contents = "("+newdata+")"   
        elif identifier[0]=='@':
            #Without parentheses
            self.contents = newdata
        else:
            raise RuntimeError("Unknown identifier encountered, expected '$*' or '@*':", identifier)

'''def main():
    spar = SParser("test.nn")
    
    spar.parse(0).print()

if __name__ == "__main__":
    main()

'''