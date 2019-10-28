module utils

open DiffSharp.AD.Float64

[<AbstractClass>]
type DiffSharpModuleBase<'input, 'output> () =
    [<DefaultValue>] val mutable packedInput : DV

    abstract member Prepare : 'input -> unit
    abstract member CalculateObjective : int -> unit
    abstract member CalculateJacobian : int -> unit
    abstract member Output : unit -> 'output

    member this.burnIn() : unit =
        // Let's build DiffSharp internal Reverse AD Trace
        // To do it just calculate the function in the another point
        // Moreover, it forces JIT-compiler to compile the function
        let oldInput = this.packedInput
        this.packedInput <- this.packedInput + 1.
        (this :> DotnetRunner.ITest<'input, 'output>).CalculateObjective(1)
        (this :> DotnetRunner.ITest<'input, 'output>).CalculateJacobian(1)
        // Put the old input back 
        this.packedInput <- oldInput
     
    interface DotnetRunner.ITest<'input, 'output> with
        member this.CalculateJacobian(times) = this.CalculateJacobian times
        member this.CalculateObjective(times) = this.CalculateObjective times
        member this.Output() = this.Output()
        member this.Prepare(input) = this.Prepare(input)