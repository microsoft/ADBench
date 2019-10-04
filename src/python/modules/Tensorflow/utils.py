import tensorflow as tf



def shape(tf_tensor):
    '''Returns shape of a tensorflow tensor like a list if integers.'''

    return tf_tensor.get_shape().as_list()