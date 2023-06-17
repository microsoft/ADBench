# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import torch



def to_torch_tensor(param, grad_req = False, dtype = torch.float64, device = 'cpu'):
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
        requires_grad = grad_req,
        device = device,
    )



def to_torch_tensors(params, grad_req = False, dtype = torch.float64, device = 'cpu'):
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
        torch.tensor(param, dtype = dtype, requires_grad = grad_req, device = device)
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
        flatten (bool, optional): if True then jacobian will be written in
            1D array row-major. Defaults to True.

    Returns:
        torch tensor, torch tensor: function result and function jacobian.
    '''

    def func_wrapper(*args, **kvs):
        out = func(*args, **kvs)
        return (out, out)

    jac_func = torch.func.jacrev(func_wrapper, tuple(range(len(inputs))), has_aux=True)
    if params != None:
        J, res = jac_func(*inputs, *params)
    else:
        J, res = jac_func(*inputs)

    # J[i].shape = (out..., in...)
    J = tuple(
        J[i].reshape(-1, inputs[i].numel())
        for i in range(len(inputs))
    )  # J[i].shape = (out, in)
    J = torch.cat(J, dim=1)  # shape = (out, (in1 + in2...))
    if flatten:
        J = J.t().flatten()

    return res, J
