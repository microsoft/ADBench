function tools = get_tools(exe_dir,python_dir,julia_dir)
% call_type:
%   0 standard - tools(id).run_cmd
%   1 theano - tools(id).run_cmd
%   2 ceres - tools(id).run_cmd+d+k
%   3 adimat
%   4 adimat vectorized
%   5 mupad
%   6 finite differences

% markers
cols = generate_colors();
markers = generate_symbols();

% tools
cpp_objective_ids = [];
tools = {};
tools(end+1).name = 'manual, C++';
tools(end).exe = [exe_dir,'Manual_cpp.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'manual_cpp';
tools(end).col = cols('manual');
tools(end).marker = markers('');
tools(end).call_type = 0;
cpp_objective_ids = [cpp_objective_ids numel(tools)];

tools(end+1).name = 'manual, Eigen';
tools(end).exe = [exe_dir,'Manual_eigen.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'manual_eigen';
tools(end).col = cols('manual');
tools(end).marker = markers('eigen');
tools(end).call_type = 0;

tools(end+1).name = 'manual, Eigen (vector)';
tools(end).exe = [exe_dir,'Manual_eigen_vector.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'manual_eigen_vector';
tools(end).col = cols('manual');
tools(end).marker = markers('eigen_vector');
tools(end).call_type = 0;

tools(end+1).name = 'Tapenade,R';
tools(end).exe = [exe_dir,'Tapenade.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'Tapenade';
tools(end).col = cols('tapenade');
tools(end).marker = markers('');
tools(end).call_type = 0;

tools(end+1).name = 'Tapenade,R (split)';
tools(end).exe = [exe_dir,'Tapenade_split.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'Tapenade_split';
tools(end).col = cols('tapenade');
tools(end).marker = markers('split');
tools(end).call_type = 0;

tools(end+1).name = 'ADOLC, R';
tools(end).exe = [exe_dir,'ADOLC.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'ADOLC';
tools(end).col = cols('adolc');
tools(end).marker = markers('');
tools(end).call_type = 0;
cpp_objective_ids = [cpp_objective_ids numel(tools)];

tools(end+1).name = 'ADOLC, R (split)';
tools(end).exe = [exe_dir,'ADOLC_split.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'ADOLC_split';
tools(end).col = cols('adolc');
tools(end).marker = markers('split');
tools(end).call_type = 0;
cpp_objective_ids = [cpp_objective_ids numel(tools)];

tools(end+1).name = 'Adept, R';
tools(end).exe = [exe_dir,'Adept.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'Adept';
tools(end).col = cols('adept');
tools(end).marker = markers('');
tools(end).call_type = 0;
cpp_objective_ids = [cpp_objective_ids numel(tools)];

tools(end+1).name = 'Adept, R (split)';
tools(end).exe = [exe_dir,'Adept_split.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'Adept_split';
tools(end).col = cols('adept');
tools(end).marker = markers('split');
tools(end).call_type = 0;
cpp_objective_ids = [cpp_objective_ids numel(tools)];

tools(end+1).name = 'Theano';
tools(end).exe = [python_dir,'Theano/Theano.py'];
tools(end).run_cmd = ['python.exe ' tools(end).exe];
tools(end).ext = 'Theano';
tools(end).col = cols('theano');
tools(end).marker = markers('');
tools(end).call_type = 1;

tools(end+1).name = 'Theano (vector)';
tools(end).exe = [python_dir 'Theano/Theano_vector.py'];
tools(end).run_cmd = ['python.exe ' tools(end).exe];
tools(end).ext = 'Theano_vector';
tools(end).col = cols('theano');
tools(end).marker = markers('vector');
tools(end).call_type = 1;

tools(end+1).name = 'Ceres, F';
tools(end).exe = [exe_dir,'Ceres/Ceresd2k5.exe'];
tools(end).run_cmd = [exe_dir,'Ceres/Ceres'];
tools(end).ext = 'Ceres';
tools(end).col = cols('ceres');
tools(end).marker = markers('');
tools(end).call_type = 2;
cpp_objective_ids = [cpp_objective_ids numel(tools)];

tools(end+1).name = 'DiffSharp';
tools(end).exe = [exe_dir,'DiffSharp/DiffSharpTests.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'DiffSharp';
tools(end).col = cols('diffsharp');
tools(end).marker = markers('automode');
tools(end).call_type = 0;

tools(end+1).name = 'DiffSharp, R';
tools(end).exe = [exe_dir,'DiffSharpR/DiffSharpTests.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'DiffSharp_R';
tools(end).col = cols('diffsharp');
tools(end).marker = markers('');
tools(end).call_type = 0;

tools(end+1).name = 'DiffSharp, R (split)';
tools(end).exe = [exe_dir,'DiffSharpRSplit/DiffSharpTests.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'DiffSharp_R_split';
tools(end).col = cols('diffsharp');
tools(end).marker = markers('split');
tools(end).call_type = 0;

tools(end+1).name = 'Autograd, R';
tools(end).exe = [python_dir 'Autograd/autograd_full.py'];
tools(end).run_cmd = ['python.exe ' tools(end).exe];
tools(end).ext = 'Autograd';
tools(end).col = cols('autograd');
tools(end).marker = markers('');
tools(end).call_type = 0;

tools(end+1).name = 'Autograd, R (split)';
tools(end).exe = [python_dir 'Autograd/autograd_split.py'];
tools(end).run_cmd = ['python.exe ' tools(end).exe];
tools(end).ext = 'Autograd_split';
tools(end).col = cols('autograd');
tools(end).marker = markers('split');
tools(end).call_type = 0;

tools(end+1).name = 'AdiMat, R';
tools(end).exe = 'gmm_objective.m';
tools(end).ext = 'adimat';
tools(end).col = cols('adimat');
tools(end).marker = markers('');
tools(end).call_type = 3;

tools(end+1).name = 'AdiMat, R (vector)';
tools(end).exe = 'gmm_objective_vector_repmat.m';
tools(end).ext = 'adimat_vector';
tools(end).col = cols('adimat');
tools(end).marker = markers('vector');
tools(end).call_type = 4;

tools(end+1).name = 'MuPAD (split)';
tools(end).exe = 'awful/matlab/example_gmm_objective_mex_d32_K5.cxx';
tools(end).ext = 'mupad';
tools(end).col = cols('mupad');
tools(end).marker = markers('split');
tools(end).call_type = 5;

tools(end+1).name = 'Julia, F';
tools(end).exe = [julia_dir 'Tests/gmm_F.jl'];
tools(end).run_cmd = ['julia.exe ' tools(end).exe];
tools(end).ext = 'Julia_F';
tools(end).col = cols('julia_f');
tools(end).marker = markers('');
tools(end).call_type = 0;

tools(end+1).name = 'Julia, F (vector)';
tools(end).exe = [julia_dir 'Tests/gmm_F_vector.jl'];
tools(end).run_cmd = ['julia.exe ' tools(end).exe];
tools(end).ext = 'Julia_F_vector';
tools(end).col = cols('julia_f');
tools(end).marker = markers('vector');
tools(end).call_type = 0;

tools(end+1).name = 'Finite differences, C++';
tools(end).col = cols('finite_differences');
tools(end).marker = markers('');
tools(end).cpp_objective_ids = cpp_objective_ids;
tools(end).call_type = 6;
