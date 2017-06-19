class FCLayer:
    def __init__(self, units, activation=None, use_bias=True, bias_initializer='zero'):
        self.units = units
        self.activation = activation
        self.use_bias = use_bias
        self.bias_initializer = bias_initializer
    
    def set_activation(self, activation):
        self.activation = activation