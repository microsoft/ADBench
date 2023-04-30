import freetensor as ft


def to_ft_tensor(param, dtype = 'float64'):
    return ft.array(param, dtype = dtype)



def to_ft_tensors(params, dtype = 'float64'):
    return tuple(
        ft.array(param, dtype = dtype)
        for param in params
    )



def ft_jacobian(func, inputs, params = None, flatten = True):
    '''Calculates jacobian and return value of the given function that uses
    FreeTensor arrays.

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

    ast = ft.jacrev(
            func, [ft.Parameter(i) for i in range(len(inputs))], ft.Return(),
            flatten=flatten, attach_backward=True)
    exe = ft.optimize(ast)
    if params is None:
        params = []
    res = exe(*inputs, *params)
    J = exe.backward()

    if flatten:

        @ft.optimize
        def post_flatten(n: ft.JIT[int], m: ft.JIT[int], x):
            x: ft.Var[(n, m), 'float64']
            return ft.flatten_pytorch(ft.transpose(x))

        J = post_flatten(J.shape[0], J.shape[1], J)

    return res, J

@ft.inline
def ft_jacobian_inline(func, inputs, params = None, flatten = True):
    '''Calculates jacobian and return value of the given function that uses
    FreeTensor arrays.

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

    ast = ft.jacrev(
            func, [ft.Parameter(i) for i in ft.static_range(len(inputs))], ft.Return(),
            flatten=flatten, attach_backward=True, tape_in_closure=False)
    if params is None:
        params = []
    res = ast(*inputs, *params)
    # FreeTensor doesn't support closures for inlined call. So pass the tapes explicitly
    # Inputs should also be passed when tape_in_closure is disabled
    tapes = {}
    if not isinstance(res, ft.VarRef):
        for ret_decl, ret_val in zip(ast.returns[1:], res[1:]):
            tapes[ret_decl.name] = ret_val
        res = res[0]
    J = ast.backward(*inputs, *params, **tapes)

    if flatten:
        J = ft.flatten_pytorch(ft.transpose(J))

    return res, J
