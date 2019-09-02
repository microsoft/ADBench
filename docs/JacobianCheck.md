# Jacobian Correctness Verification

ADBench needs not only to measure the time different tools take to compute the Jacobians of objective functions, but also to check, whether produced Jacobians are accurate. This document describes, how the accuracy of the Jacobians is verified.

## Source of the Ground Truth

Some of our tests (most notably, those related to bundle adjustments) result in very large Jacobians. In fact, a complete set of correct Jacobians for all our tests in tsv format consumes more than 20 GB of storage. As such, it is not feasible to check such a set into the repository. So instead, we designate one of the _testing modules_ to be _golden module_ - the source of ground truth, against output of which Jacobians produced by all the other _testing modules_ will be checked.

The accuracy of the results produced by the _golden module_ is verified separately.

We designate the module `Manual`, which computes the Jacobians using the manually derived formulae, as the _golden module_. We do so, because
- It is fast enough not to timeout, so when some other module produces a Jacobian, we would have a Jacobian, we consider accurate, to compare it against
- We have the complete control over this module, so if we ever encounter a bug in it, it will be within our power to fix it

Below we will refer to Jacobians produced by the _golden module_ as _golden Jacobians_.

## Comparing Jacobians

We consider a Jacobian produced by a _testing module_ accurate when its dimensions are equal to those of the _golden Jacobian_, and when all its elements are _near_ the corresponding elements of the _golden Jacobian_.

We say, that two floating-point numbers are _near_, when the difference between them, defined as

<table>
  <tr>
    <td>
        <code>
            ρ(x, y) = |x - y| / max(1, |x| + |y|)
        </code>
    </td>
    <td>(1)</td>
  </tr>
</table>

is smaller than the given _tolerance_. Note, that the formula (1) produces the absolute difference between `x` and `y`, when both lie in the vicinity of zero, and the relative one otherwise, which is a suitable way of comparing floating-point numbers.

We generally use the tolerance of `1e-6` to allow for rounding errors during both the computation and the output. This number may be adjusted for specific tests, e.g. it can be increased when the _testing module_ uses single-precision arithmetic.

## Verification of the Golden Module

To assert the correctness of `Manual` - the designated _golden module_, we compare the Jacobians it produces to ones obtained via finite differences (specifically, central differences) method.

Computing all the Jacobians using finite differences is a very time consuming process, so it is not done by the _global runner_ (_global runner_ still runs the finite differences as on of the benchmarks, but just like with all the other _testing modules_, it enforces the hard time limit on it). Instead, we have a separate script for that - `ADBench/compare-manvfinite.ps1`.

It is still unfeasible to compute the complete gradients for large GMM problems using finite differences, so we compute only parts of them, and compare them to the corresponding parts of the gradients computed by `Manual`.
This is done by a separate utility - `src/cpp/utils/finitePartialGmm`.

The script `ADBench/compare-manvfinite.ps1` computes all the Jacobians using `Manual` and `Finite` modules (except GMM, see above) and outputs (alongside said Jacobians) a log, containing the following statistics for each pair of the Jacobians:
- Whether or not the Jacobians have different shapes
- Whether or not one of the Jacobians failed to parse
- Maximum encountered difference (1) between the corresponding elements of the Jacobians
- Average difference (1) between the corresponding elements of the Jacobians
- Number of encountered differences (1) that exceed the tolerance (`1e-6`)
- Total number of the compared pairs of elements

Note, that we should expect that some differences between the corresponding elements of the Jacobian will be larger than the tolerance, because of the central difference formula's truncation error.
This happens especially often for the 2.5M points GMM problem.

So, if the `Manual` module is implemented incorrectly, we would immediately see that reflected in the log in the form large average differences and big numbers of difference-exceeding-tolerance cases in most of the tests. If the `Manual` if correct, then we'll see small maximum encountered difference in most of the tests. Still, due to the aforementioned truncation error, there may be some cases of large difference even when the `Manual` module produces correct Jacobians. These cases should be checked independently, e.g. by comparing `Manual`'s Jacobians to those produced by some other AD tool.