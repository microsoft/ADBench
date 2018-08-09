rem TODO need to call vcvarsall or soemthing

fsc -d:MODE_AD -d:DO_GMM_FULL --lib:"C:\Users\Zak Smith\CMakeBuilds\95e43dd6-1979-0633-8dca-9ab4e04499c8\build\x64-Debug\tools\DiffSharp" --reference:DiffSharp.dll --reference:MathNet.Numerics.dll --reference:MathNet.Numerics.FSharp.dll gmm.fs Program.fs

rem TODO add FSharp.Quotations.Evaluator and FsAlg
