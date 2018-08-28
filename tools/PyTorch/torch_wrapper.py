import torch


# Recursively call .backward on multi-dimensional output
def recurse_backwards(output, inputs, J):
    if output.dim() > 0:
        for item in output:
            recurse_backwards(item, inputs, J)
    else:
        for inp in inputs:
            inp.grad = None
        output.backward(retain_graph=True)
        J.append(torch.stack(list(inp.grad for inp in inputs)))


# Run a function with torch tensors
def torch_func(func, inputs, params, do_J):
    inputs = tuple(torch.tensor(inp, dtype=torch.float64, requires_grad=do_J) for inp in inputs)
    params = tuple(torch.tensor(param, dtype=torch.float64) for param in params)

    res = func(*inputs, *params)

    if do_J:
        J = []
        recurse_backwards(res, inputs, J)
        J = torch.stack(J)
    else:
        J = None

    return res, J
