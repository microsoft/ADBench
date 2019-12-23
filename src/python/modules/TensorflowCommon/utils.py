# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import tensorflow as tf



def to_tf_tensor(ndarray, dtype = tf.float64):
    '''Converts the given multidimensional array to a tensorflow tensor.

    Args:
        ndarray (ndarray-like): parameter for conversion.
        dtype (type, optional): defines a type of tensor elements. Defaults to
            tf.float64.

    Returns:
        tensorflow tensor
    '''

    return tf.convert_to_tensor(ndarray, dtype = dtype)



def shape(tf_tensor):
    '''Returns shape of a tensorflow tensor like a list if integers.'''

    return tf_tensor.get_shape().as_list()



def flatten(tf_tensor, column_major = False):
    '''Returns the flaten tensor.'''

    if column_major:
        tf_tensor = tf.transpose(tf_tensor)
        
    return tf.reshape(tf_tensor, [-1])