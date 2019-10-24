module lstm

open DiffSharp.AD.Float64
open DotnetRunner.Data
open System.Composition
open DiffSharp.Util

let lstmModel (weight: DV) (bias: DV) (hidden: DV) (cell: DV) (input: DV) : DV * DV =
    let hsize = hidden.Length
    let forget = sigmoid (input .* weight.[0..hsize - 1] + bias.[0..hsize - 1])
    let ingate = sigmoid (hidden .* weight.[hsize..2 * hsize - 1] + bias.[hsize..2 * hsize - 1])
    let outgate = sigmoid (input .* weight.[2 * hsize..3 * hsize - 1] + bias.[2 * hsize..3 * hsize - 1])
    let change = tanh (hidden .* weight.[3 * hsize..4 * hsize - 1] + bias.[3 * hsize..4 * hsize - 1])

    let cell2 = cell .* forget + ingate .* change
    let hidden2 = outgate .* tanh (cell2)
    hidden2, cell2

let lstmPredict (mainParams: DM) (extraParams: DM) (state: DM) (input: DV) : DV * DM =
    let x = input .* extraParams.[0, *]
    let lenState = state.Rows / 2
    let s2list, x2 = [0..lenState - 1]
                        |> List.fold (fun (acc:DV list * DV) i -> 
                            let s, x = acc
                            let h, c = lstmModel mainParams.[2 * i, *] mainParams.[2 * i + 1, *] state.[2 * i, *] state.[2 * i + 1, *] x
                            (c::h::s, h)
                            ) ([], x)
    x2 .* extraParams.[1, *] + extraParams.[2, *], DM.ofRows (List.rev s2list)

let lstmObjective (mainParams: DM) (extraParams: DM) (state: DM) (sequence: DM) : D =
    let lenSeq = sequence.Rows
    let count = sequence.Cols * (sequence.Rows - 1)
    let total = [0..lenSeq - 2]
                |> List.fold (fun (acc:DM * D) i ->
                    let oldState, oldTotal = acc
                    let ypred, newState = lstmPredict mainParams extraParams oldState sequence.[i, *]
                    let ynorm = ypred - log (DV.Sum (exp ypred) + 2.)
                    newState, oldTotal + sequence.[i + 1, *] * ynorm) (state, D 0.)
                |> snd
    -total / count

[<Export(typeof<DotnetRunner.ITest<LSTMInput, LSTMOutput>>)>]
type DiffSharpLSTM() =
    [<DefaultValue>] val mutable input : LSTMInput
    [<DefaultValue>] val mutable packedInput : DV
    [<DefaultValue>] val mutable lstmObjectiveWrapper : DV -> D
    let mutable objective : D = D 0.
    let mutable gradient : DV = DV.empty
     
    interface DotnetRunner.ITest<LSTMInput, LSTMOutput> with
        member this.Prepare(input: LSTMInput) : unit = 
            this.input <- input
            this.packedInput <- Array.map toDV (Array.append input.MainParams input.ExtraParams) |> DV.concat
            let mainParamsSliceCount = 2 * input.LayerCount
            let mainParamsSize = 8 * input.LayerCount * input.CharBits
            let stateDM = input.State |> Seq.ofArray |> Seq.map Seq.ofArray |> toDM
            let sequenceDM = input.Sequence |> Seq.ofArray |> Seq.map Seq.ofArray |> toDM
            this.lstmObjectiveWrapper <- (fun par ->
                let mainParams = DV.splitEqual mainParamsSliceCount par.[0..mainParamsSize - 1] |> DM.ofRows
                let extraParams = DV.splitEqual 3 par.[mainParamsSize..] |> DM.ofRows
                lstmObjective mainParams extraParams stateDM sequenceDM)
            // Let's build DiffSharp internal Reverse AD Trace
            // To do it just calculate the function in the another point
            // Moreover, it forces JIT-compiler to compile the function
            let oldInput = this.packedInput
            this.packedInput <- this.packedInput + 1.
            (this :> DotnetRunner.ITest<LSTMInput, LSTMOutput>).CalculateObjective(1)
            (this :> DotnetRunner.ITest<LSTMInput, LSTMOutput>).CalculateJacobian(1)
            // Put the old input back 
            this.packedInput <- oldInput

        member this.CalculateObjective(times: int) : unit =
            [1..times] |> List.iter (fun _ ->
                objective <- this.lstmObjectiveWrapper this.packedInput
            )

        member this.CalculateJacobian(times: int) : unit =
            [1..times] |> List.iter (fun _ ->
                gradient <- grad this.lstmObjectiveWrapper this.packedInput
            )
            
        member this.Output() : LSTMOutput = 
            let mutable output = new LSTMOutput()
            output.Objective <- convert objective
            output.Gradient <- convert gradient
            output

