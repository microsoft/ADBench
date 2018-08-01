from _fitsubdiv import *

# Custom stringification method for Theta class
Theta.__str__ = lambda(self) : '[' + ' '.join([str(x) for x in self]) + ']' 
