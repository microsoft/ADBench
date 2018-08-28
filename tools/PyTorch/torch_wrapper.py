import torch


# Recursively call .backward on multi-dimensional output
def recurse_backwards(output, inputs, J, flatten=False):
    if output.dim() > 0:
        for item in output:
            recurse_backwards(item, inputs, J)
    else:
        for inp in inputs:
            inp.grad = None
        output.backward(retain_graph=True)
        if flatten:
            J.append(torch.cat(list(inp.grad.flatten() for inp in inputs)))
        else:
            J.append(torch.stack(list(inp.grad for inp in inputs)))


# Run a function with torch tensors
def torch_func(func, inputs, params, do_J, flatten=False):
    inputs = tuple(torch.tensor(inp, dtype=torch.float64, requires_grad=do_J) for inp in inputs)
    params = tuple(torch.tensor(param, dtype=torch.float64) for param in params)

    res = func(*inputs, *params)

    if do_J:
        J = []
        recurse_backwards(res, inputs, J, flatten)
        J = torch.stack(J)
    else:
        J = None

    return res, J
