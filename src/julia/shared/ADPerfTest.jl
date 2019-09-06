module ADPerfTest

export Test

struct Test{Input, Output}
    context::Any
    prepare!::Function
    calculate_objective!::Function
    calculate_jacobian!::Function
    output!::Function
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