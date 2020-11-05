module utils

open DiffSharp
type D = Tensor
type DV = Tensor
type DM = Tensor

(*
let d (x: float) : D = dsharp.tensor x
let dv (x: float[]) : DV = dsharp.tensor x
let dm (x: float[,]) : DM = dsharp.tensor x
module DV =
    let l2normSq (x: DV) : D = 
        dsharp.sum(x*x)

    let l2norm (x: DV) : D = 
        sqrt(l2normSq(x))

*)

type dsharp with
    static member max(t: Tensor, dim: int) = 
        // todo - not right for dim > 2
        t.unstack(dim) |> Array.map (fun t -> t.max()) |> fun ts -> dsharp.stack(ts, dim)

        
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