import re
import functools
import inspect
import numpy as np
import freetensor as ft

from modules.FreeTensor.utils import to_ft_tensor, to_ft_tensors
from shared.ITest import ITest
from shared.GMMData import GMMInput, GMMOutput
from modules.FreeTensor.gmm_objective import gmm_objective_inline



class FreeTensorEnzymeGMM(ITest):
    '''Test class for GMM differentiation by FreeTensor.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        ft.config.set_fast_math(False)
        ft.config.set_backend_compiler_cxx(['/utils/clang/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-/bin/clang++'])

        self.inputs = to_ft_tensors((input.alphas, input.means, input.icf))
        self.params = to_ft_tensors((input.x, input.wishart.gamma)) + (to_ft_tensor(input.wishart.m, "int32"),)

        self.d = input.means.shape[1]
        self.k = input.alphas.shape[0]
        self.n = input.x.shape[0]
        assert input.alphas.shape == (self.k,)
        assert input.means.shape == (self.k, self.d)
        assert input.icf.shape == (self.k, self.d * (self.d + 1) // 2)
        assert input.x.shape == (self.n, self.d)

        @ft.codegen
        @ft.lower(skip_passes=['make_heap_alloc'])  # Enzyme has bugs handling dynamic allocation?
        @ft.schedule(callback=lambda s: s.auto_schedule(ft.CPU()))
        @ft.transform
        def gmm_objective(
                alphas, means, icf, x, wishart_gamma, wishart_m,
                out,  # It seems Enzyme can't correctly handle dynamicly allocated return value
                d: ft.JIT[int],
                k: ft.JIT[int],
                n: ft.JIT[int]):
            alphas: ft.Var[(k,), "float64"]
            means: ft.Var[(k, d), "float64"]
            icf: ft.Var[(k, d * (d + 1) // 2), "float64"]
            x: ft.Var[(n, d), "float64"]
            wishart_gamma: ft.Var[(), "float64"]
            wishart_m: ft.Var[(), "int32"]
            out: ft.Var[(), "float64", "output"]
            tmp = gmm_objective_inline(alphas, means, icf, x, wishart_gamma, wishart_m)
            if ft.ndim(tmp) == 0:
                out[...] = tmp
            else:
                assert tmp.shape(0) == 1
                out[...] = tmp[0]

        self.comp_objective = ft.build_binary(gmm_objective)

        class EnzymeJITTemplate(ft.jit.JITTemplate):

            @functools.cache
            def instantiate_by_only_jit_args(self, *jit_args):
                old_native_code = gmm_objective.instantiate_by_only_jit_args(*jit_args)
                code = old_native_code.code
                code = re.sub('void run', '__attribute__((always_inline)) void run', code)  # Work around Enyzme issue #1244
                code += '''
void run_wrapper(double *alphas, double *means, double *icf, double *x, double *wishart_gamma, int32_t *wishart_m, double *out, CPUContext_t ctx) {
    void *params[] = {alphas, means, icf, x, wishart_gamma, wishart_m, out};
    void *returns[] = {};
    size_t *retShapes[] = {};
    size_t retDims[] = {};
    run(params, returns, retShapes, retDims, ctx);
}

void __enzyme_autodiff(...);
int enzyme_dup;
int enzyme_out;
int enzyme_const;

extern "C" void d_run(void **params, void **returns, size_t **retShapes, size_t *retDims, CPUContext_t ctx) {
    double d_out = 1;
    __enzyme_autodiff(run_wrapper,
        enzyme_dup, (double*)params[0], (double*)params[7],
        enzyme_dup, (double*)params[1], (double*)params[8],
        enzyme_dup, (double*)params[2], (double*)params[9],
        enzyme_const, (double*)params[3],
        enzyme_const, (double*)params[4],
        enzyme_const, (int32_t*)params[5],
        enzyme_dup, (double*)params[6], &d_out,
        enzyme_const, ctx);
}
'''
                params = old_native_code.params
                returns = old_native_code.returns
                assert len(params) == 7
                assert len(returns) == 0
                #params.append(ft.ffi.NativeCodeParam("__d_alphas", params[0].dtype, ft.AccessType('inout'), params[0].mtype))
                #params.append(ft.ffi.NativeCodeParam("__d_means", params[1].dtype, ft.AccessType('inout'), params[1].mtype))
                #params.append(ft.ffi.NativeCodeParam("__d_icf", params[2].dtype, ft.AccessType('inout'), params[2].mtype))
                params.append(ft.ffi.NativeCodeParam("__d_alphas", ft.DataType("float64"), ft.AccessType('inout'), ft.MemType("cpu")))
                params.append(ft.ffi.NativeCodeParam("__d_means", ft.DataType("float64"), ft.AccessType('inout'), ft.MemType("cpu")))
                params.append(ft.ffi.NativeCodeParam("__d_icf", ft.DataType("float64"), ft.AccessType('inout'), ft.MemType("cpu")))
                return ft.NativeCode(old_native_code.name, params, [], code, "d_run", old_native_code.target)

        def d_run(
                alphas, means, icf, x, wishart_gamma, wishart_m, out,
                __d_alphas, __d_means, __d_icf,
                d: ft.JIT[int],
                k: ft.JIT[int],
                n: ft.JIT[int]):
            pass  # Only used for function signature

        self.comp_jacobian = ft.build_binary(
                EnzymeJITTemplate(inspect.signature(d_run).parameters, ['d', 'k', 'n']),
                cxx_flags=['-Xclang', '-load', '-Xclang', '/utils/enzyme/Enzyme-0.0.66-llvm-12/enzyme/build/Enzyme/ClangEnzyme-12.so',
                           #'-O0' # Optimization does not work?
                           ])

        @ft.optimize(schedule_callback=lambda s: s.auto_schedule(ft.CPU()))
        def init_grad(
                d: ft.JIT[int],
                k: ft.JIT[int],
                n: ft.JIT[int]):
            d_alphas = ft.zeros((k,), "float64")
            d_means = ft.zeros((k, d), "float64")
            d_icf = ft.zeros((k, d * (d + 1) // 2), "float64")
            return d_alphas, d_means, d_icf

        self.init_grad = init_grad

        @ft.optimize(schedule_callback=lambda s: s.auto_schedule(ft.CPU()))
        def merge_grad(
                d_alphas, d_means, d_icf,
                d: ft.JIT[int],
                k: ft.JIT[int],
                n: ft.JIT[int]):
            d_alphas: ft.Var[(k,), "float64"]
            d_means: ft.Var[(k, d), "float64"]
            d_icf: ft.Var[(k, d * (d + 1) // 2), "float64"]
            return ft.concat([ft.flatten_pytorch(d_alphas), ft.flatten_pytorch(d_means), ft.flatten_pytorch(d_icf)])

        self.merge_grad = merge_grad

    def output(self):
        '''Returns calculation result.'''

        return GMMOutput(self.objective.numpy().item(), self.gradient.numpy())

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.objective = ft.array(0, dtype="float64")
            self.comp_objective(*self.inputs, *self.params, self.objective, self.d, self.k, self.n)

    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for i in range(times):
            self.objective = ft.array(0, dtype="float64")
            d_alphas, d_means, d_icf = self.init_grad(self.d, self.k, self.n)
            self.comp_jacobian(
                *self.inputs, *self.params, self.objective,
                d_alphas, d_means, d_icf,
                self.d, self.k, self.n
            )
            self.gradient = self.merge_grad(d_alphas, d_means, d_icf, self.d, self.k, self.n)
