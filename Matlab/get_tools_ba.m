function tools = get_tools_ba(exe_dir,python_dir,julia_dir)
% call_type:
%   0 standard - tools(id).run_cmd
%   1 theano - tools(id).run_cmd
%   2 ceres - tools(id).run_cmd+d+k
%   3 adimat
%   4 adimat sparse
%   5 mupad

% markers
cols = generate_colors();
markers = generate_symbols();

% tools
tools = {};
cpp_objective_ids = [];

% tools(end+1).name = 'manual, C++';
% tools(end).exe = [exe_dir,'Manual_cpp.exe'];
% tools(end).run_cmd = tools(end).exe;
% tools(end).ext = 'manual_cpp';
% tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id+1;
% tools(end).marker = markers{1};
% tools(end).call_type = 0;

tools(end+1).name = 'manual | C++ Eigen';
tools(end).exe = [exe_dir,'Manual_eigen.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'manual_eigen';
tools(end).col = cols('manual');
tools(end).marker = markers('eigen');
tools(end).call_type = 0;

tools(end+1).name = 'Tapenade | C';
tools(end).exe = [exe_dir,'Tapenade.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'Tapenade';
tools(end).col = cols('tapenade');
tools(end).marker = markers('');
tools(end).call_type = 0;

tools(end+1).name = 'ADOLC | C++';
tools(end).exe = [exe_dir,'ADOLC.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'ADOLC';
tools(end).col = cols('adolc');
tools(end).marker = markers('');
tools(end).call_type = 0;
cpp_objective_ids = [cpp_objective_ids numel(tools)];

tools(end+1).name = 'ADOLC (autosparse) | C++';
tools(end).exe = [exe_dir,'ADOLC_sparse.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'ADOLC_sparse';
tools(end).col = cols('adolc');
tools(end).marker = markers('sparse');
tools(end).call_type = 0;
cpp_objective_ids = [cpp_objective_ids numel(tools)];

tools(end+1).name = 'ADOLC | C++ Eigen';
tools(end).exe = [exe_dir,'ADOLC_eigen.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'ADOLC_eigen';
tools(end).col = cols('adolc');
tools(end).marker = markers('eigen');
tools(end).call_type = 0;

tools(end+1).name = 'ADOLC (autosparse) | C++ Eigen';
tools(end).exe = [exe_dir,'ADOLC_sparse_eigen.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'ADOLC_sparse_eigen';
tools(end).col = cols('adolc');
tools(end).marker = markers('eigen_sparse');
tools(end).call_type = 0;

tools(end+1).name = 'Adept | C++';
tools(end).exe = [exe_dir,'Adept.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'Adept';
tools(end).col = cols('adept');
tools(end).marker = markers('');
tools(end).call_type = 0;
cpp_objective_ids = [cpp_objective_ids numel(tools)];

tools(end+1).name = 'Theano | Python';
tools(end).exe = [python_dir,'Theano/Theano_ba.py'];
tools(end).run_cmd = ['python.exe ' tools(end).exe];
tools(end).ext = 'Theano';
tools(end).col = cols('theano');
tools(end).marker = markers('');
tools(end).call_type = 1;

tools(end+1).name = 'Ceres | C++';
tools(end).exe = [exe_dir,'Ceres.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'Ceres';
tools(end).col = cols('ceres');
tools(end).marker = markers('');
tools(end).call_type = 0;
cpp_objective_ids = [cpp_objective_ids numel(tools)];

tools(end+1).name = 'DiffSharp | F#';
tools(end).exe = [exe_dir,'DiffSharp/DiffSharpTests.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'DiffSharp';
tools(end).col = cols('diffsharp');
tools(end).marker = markers('automode');
tools(end).call_type = 0;

tools(end+1).name = 'DiffSharp-R | F#';
tools(end).exe = [exe_dir,'DiffSharpR/DiffSharpTests.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'DiffSharp_R';
tools(end).col = cols('diffsharp');
tools(end).marker = markers('');
tools(end).call_type = 0;

tools(end+1).name = 'Autograd | Python';
tools(end).exe = [python_dir 'Autograd/autograd_ba.py'];
tools(end).run_cmd = ['python.exe ' tools(end).exe];
tools(end).ext = 'Autograd';
tools(end).col = cols('autograd');
tools(end).marker = markers('');
tools(end).call_type = 0;

tools(end+1).name = 'ADiMat | MATLAB';
tools(end).exe = 'ba_compute_reproj_err.m';
tools(end).ext = 'adimat';
tools(end).col = cols('adimat');
tools(end).marker = markers('');
tools(end).call_type = 3;

tools(end+1).name = 'ADiMat (sparse) | MATLAB';
tools(end).exe = 'ba_objective.m';
tools(end).ext = 'adimat_sparse';
tools(end).col = cols('adimat');
tools(end).marker = markers('sparse');
tools(end).call_type = 4;

tools(end+1).name = 'MuPAD | MATLAB symbolic';
tools(end).exe = 'mupad/mupad_ba_compute_reproj_err_mex.cxx';
tools(end).ext = 'mupad';
tools(end).col = cols('mupad');
tools(end).marker = markers('');
tools(end).call_type = 5;

tools(end+1).name = 'Julia-F | Julia';
tools(end).exe = [julia_dir 'Tests/ba_F.jl'];
tools(end).run_cmd = ['julia.exe ' tools(end).exe];
tools(end).ext = 'Julia_F';
tools(end).col = cols('julia_f');
tools(end).marker = markers('');
tools(end).call_type = 0;

tools(end+1).name = 'Finite differences | C++';
tools(end).col = cols('finite_differences');
tools(end).marker = markers('');
tools(end).cpp_objective_ids = cpp_objective_ids;
tools(end).call_type = 6;
