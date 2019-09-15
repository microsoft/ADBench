import torch



def to_torch_tensor(param, grad_req = False, dtype = torch.float64):
    '''Converts given single parameter to torch tensors. Note that parameter
    can be an ndarray-like object.
    
    Args:
        param (ndarray-like): parameter to convert.
        grad_req (bool, optional): defines flag for calculating tensor
            jacobian for created torch tensor. Defaults to False.
        dtype (type, optional): defines a type of tensor elements. Defaults to
            torch.float64.

    Returns:
        torch tensor
    '''

    return torch.tensor(
        param,
        dtype = dtype,
        requires_grad = grad_req
    )



def to_torch_tensors(params, grad_req = False, dtype = torch.float64):
    '''Converts given multiple parameters to torch tensors. Note that
    parameters can be ndarray-lake objects.
    
    Args:
        params (enumerable of ndarray-like): parameters to convert.
        grad_req (bool, optional): defines flag for calculating tensor
            jacobian for created torch tensors. Defaults to False.
        dtype (type, optional): defines a type of tensor elements. Defaults to
            torch.float64.

    Returns:
        tuple of torch tensors
    '''

    return tuple(
        torch.tensor(param, dtype = dtype, requires_grad = grad_req)
        for param in params
    )



def torch_jacobian(func, inputs, params = None, flatten = True):
    '''Calculates jacobian and return value of the given function that uses
    torch tensors.

    Args:
        func (callable): function which jacobian is calculating.
        inputs (tuple of torch tensors): function inputs by which it is
            differentiated.
        params (tuple of torch tensors, optional): function inputs by which it
            is doesn't differentiated. Defaults to None.

    Returns:
        torch tensor, torch tensor: function result and function jacobian.
            Note that jacobian is stored in a 1D tensor column-major.
    '''

    def recurse_backwards(output, inputs, J):
        '''Recursively calls .backward on multi-dimensional output.'''

        def get_flatten(tensor):
            '''Returns tensor gradient flatten representation. Added for
            performing concatenation of scalar tensors gradients.'''

            if tensor.dim() > 0:
                return tensor.grad.flatten()
            else:
                return tensor.grad.view(1)


        if output.dim() > 0:
            for item in output:
                recurse_backwards(item, inputs, J)
        else:
            for inp in inputs:
                inp.grad = None
            output.backward(retain_graph = True)
            J.append(torch.cat(list(get_flatten(inp) for inp in inputs)))


    if params != None:
        res = func(*inputs, *params)
    else:
        res = func(*inputs)

    J = []
    recurse_backwards(res, inputs, J)
    J = torch.stack(J).t().flatten()

    return res, J