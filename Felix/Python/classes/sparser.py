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
    
    def print(self):
        if not self.children:
            print("Argument:", self.root)
        else:
            print("Keyword:", self.root)
            for child in self.children:
                child.print()
    
    def replace(self, identifier, content):
        if str(self.root) == "@"+identifier:
            self.root = SNode(content, self.children)
        if str(self.root) == "$"+identifier:
            self.root = SNode("("+content+")", self.children)
        if self.children:
            for child in self.children:
                child.replace(identifier, content)

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
                print("ROOT OF SEXPR:", str(sexpr.children[0].root))
                if str(sexpr.children[-1].root).strip() == "import":
                    print("FOUND IMPORT CLAUSE")
                    try:
                        imp = open(sexpr.children[-1].children[1].root, 'r').read()
                        #sexpr.replace(sexpr.children[-1].children[0].root, imp)
                        self.find_and_replace(sexpr.children[-1].children[0].root, imp)
                    except OSError:
                        print("ERROR: Could not open specified file:", sexpr.children[0].children[1].root)
                        exit()
                if str(sexpr.children[-1].root).strip() == "define":
                    print("FOUND DEFINE CLAUSE")
                    imp = "data "+" ".join(map(str,sexpr.children[-1].children[1].children))
                    #sexpr.replace(sexpr.children[-1].children[0].root, imp)
                    self.find_and_replace(sexpr.children[-1].children[0].root, imp)
                if str(sexpr.children[-1].root).strip() == "data":
                    print("FOUND DATA CLAUSE")
                    for datum in sexpr.children[-1].children:
                        try:
                            if float(datum.root) != float(datum.root): #Check if NaN!=NaN, as defined
                                raise RuntimeError("Found non-number in S-Expression starting with 'data'.")
                        except ValueError:
                            print("ERROR: Found non-number in S-Expression starting with 'data':", datum.root)
                            exit()
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
        #print("Cursor is at position:", self.cursor)
        #print("Last char read:", self.contents[self.cursor])
        newdata = self.contents[0:self.cursor] + self.contents[self.cursor:].replace("@"+identifier, content)
        newdata = newdata[0:self.cursor]+newdata[self.cursor:].replace("$"+identifier, "("+content+")")
        self.contents = newdata
        print("Replaced " + identifier + " with " + content)

'''def main():
    spar = SParser("test.nn")
    
    spar.parse(0).print()

if __name__ == "__main__":
    main()

'''