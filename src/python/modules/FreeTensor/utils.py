import freetensor as ft


def to_ft_tensor(param, dtype = 'float64'):
    return ft.array(param, dtype = dtype)



def to_ft_tensors(params, dtype = 'float64'):
    return tuple(
        ft.array(param, dtype = dtype)
        for param in params
    )


def ft_jacobian(func, n_inputs, flatten = True, schedule_callback = None, device = None):
    '''Calculates jacobian and return value of the given function that uses
    FreeTensor arrays.

    Args:
        func (callable): function which jacobian is calculating.
        flatten (bool, optional): if True then jacobian will be written in
            1D array row-major. Defaults to True.

    Returns:
        fn(inputs, params) -> (torch tensor, torch tensor): Function to compute
        function result and function jacobian.
    '''

    if device is None:
        device = ft.config.default_device()

    with device:
        ast = ft.jacrev(
                func, [ft.Parameter(i) for i in range(n_inputs)], ft.Return(),
                flatten=True, attach_backward=True)
        exe = ft.optimize(ast, schedule_callback=schedule_callback)

        @ft.optimize(schedule_callback=schedule_callback)
        def post_flatten(n: ft.JIT[int], m: ft.JIT[int], x):
            x: ft.Var[(n, m), 'float64']
            return ft.flatten_pytorch(ft.transpose(x))

    def f(inputs, params = None):
        assert len(inputs) == n_inputs

        if params is None:
            params = []
        res = exe(*inputs, *params)
        J = exe.backward()
        if flatten:
            J = post_flatten(J.shape[0], J.shape[1], J)
        return res, J

    return f

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
            flatten=True, attach_backward=True, tape_in_closure=False)
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
