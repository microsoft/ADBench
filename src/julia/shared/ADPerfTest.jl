module ADPerfTest

export Test

"""
Julia automatic differentiation performance testing module for an objective
corresponding to given Input and Output types. Differentiates the objective
using some AD framework.
"""
struct Test{Input, Output}
    """
    An object containing the state of the `Test`. Is passed to every callback
    during the benchmarking.
    """
    context::Any
    """
        test.prepare!(context, input::Input)
    
    Converts the input data from the `Input` type in which it is provided by
    the calling benchmark runner into the format optimized for use with the 
    tested AD framework.
    Stores it in the `context`.

    Optionally, performs other preparatory activities need by the tested AD framework.
    """
    prepare!::Function
    """
        test.calculate_objective!(context, times::Int)
    
    Repeatedly computes the objective function `times` times for the input
    stored in the context. Stores results in the context.
    """
    calculate_objective!::Function
    """
        test.calculate_jacobian!(context, times::Int)
    
    Repeatedly computes the jacobian of the objective function `times` times
    for the input stored in the context. Stores results in the context.
    """
    calculate_jacobian!::Function
    """
        test.output!(output::Output, context)
    
    Convertes outputs saved in the `context` into the format specified by the runner.
    """
    output!::Function
    """
    Creates a Test{Input, Output} object. Checks that all the callbacks have all
    the necessary methods.
    """
    function Test{Input, Output}(empty_context::Context, prepare!::Function, calculate_objective!::Function, calculate_jacobian!::Function, output!::Function) where {Input, Output, Context}
        if !Base.hasmethod(prepare!, Tuple{Context, Input})
            throw(ArgumentError("$(string(prepare!)) doesn't have a method matching $(string(prepare!))(::$(string(Context)), ::$(string(Input)))."))
        end
        if !Base.hasmethod(calculate_objective!, Tuple{Context, Int})
            throw(ArgumentError("$(string(calculate_objective!)) doesn't have a method matching $(string(calculate_objective!))(::$(string(Context)), ::$(string(Int)))."))
        end
        if !Base.hasmethod(calculate_jacobian!, Tuple{Context, Int})
            throw(ArgumentError("$(string(calculate_jacobian!)) doesn't have a method matching $(string(calculate_jacobian!))(::$(string(Context)), ::$(string(Int)))."))
        end
        if !Base.hasmethod(output!, Tuple{Output, Context})
            throw(ArgumentError("$(string(output!)) doesn't have a method matching $(string(output!))(::$(string(Output)), ::$(string(Context)))."))
        end
        new{Input, Output}(empty_context, prepare!, calculate_objective!, calculate_jacobian!, output!)
    end
end

end