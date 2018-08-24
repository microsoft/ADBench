import torch


# Run a function with torch tensors
def torch_func(func, inputs, params, do_J):
    inputs = tuple(torch.tensor(inp, requires_grad=do_J) for inp in inputs)
    params = tuple(torch.tensor(param) for param in params)

    print("Start func")
    res = func(*inputs, *params)
    print("End func")

    if do_J:
        if res.dim() > 0:
            for output in res:
                print("Output.backward")
                output.backward(retain_graph=True)
                print("Get grads")
                grad = tuple(inp.grad for inp in inputs)
                print("GRAD:", grad)
        else:
            res.backward()
            grad = tuple(inp.grad for inp in inputs)
    else:
        grad = None
    print("Return grads")
    return res, grad
