function tools = get_tools_hand(exe_dir,python_dir,julia_dir)
% call_type:
%   0 standard - tools(id).run_cmd
%   1 theano - tools(id).run_cmd
%   2 ceres - tools(id).run_cmd+d+k
%   3 adimat
%   4 adimat sparse
%   5 mupad

% markers
cols = [.8 .1 0;
        0 .7 0;
        .2 .2 1;
        0 0 0;
        .8 .8 0;
        0.6 0.5 0.1;
        1 .45 0;
        0.45 0.85 0.45;
        0 .8 .8;
        .8 0 .8;
        0 1 0];
markers = {'s', 'x', '^', 'none'};

% tools
tools = {};
unused_col_id = 1;

% tools(end+1).name = 'manual, C++';
% tools(end).exe = [exe_dir,'Manual_cpp.exe'];
% tools(end).run_cmd = tools(end).exe;
% tools(end).ext = 'manual_cpp';
% tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id+1;
% tools(end).marker = markers{1};
% tools(end).call_type = 0;

% tools(end+1).name = 'manual, Eigen';
% tools(end).exe = [exe_dir,'Manual_eigen.exe'];
% tools(end).run_cmd = tools(end).exe;
% tools(end).ext = 'manual_eigen';
% tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id+1;
% tools(end).marker = markers{1};
% tools(end).call_type = 0;

% tools(end+1).name = 'Tapenade, R';
% tools(end).exe = [exe_dir,'Tapenade.exe'];
% tools(end).run_cmd = tools(end).exe;
% tools(end).ext = 'Tapenade';
% tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
% tools(end).marker = markers{1};
% tools(end).call_type = 0;

tools(end+1).name = 'ADOLC, Eigen';
tools(end).exe = [exe_dir,'ADOLC_eigen.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'ADOLC_eigen';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 0;

tools(end+1).name = 'ADOLC, Eigen (sparse)';
tools(end).exe = [exe_dir,'ADOLC_eigen_sparse.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'ADOLC_eigen_sparse';
tools(end).col = tools(end-1).col;
tools(end).marker = markers{2};
tools(end).call_type = 0;
% 
% tools(end+1).name = 'ADOLC, tapeless';
% tools(end).exe = [exe_dir,'ADOLC_tapeless.exe'];
% tools(end).run_cmd = tools(end).exe;
% tools(end).ext = 'ADOLC_tapeless';
% tools(end).col = tools(end-2).col;
% tools(end).marker = markers{3};
% tools(end).call_type = 0;
% 
% tools(end+1).name = 'ADOLC, tapeless (sparse)';
% tools(end).exe = [exe_dir,'ADOLC_tapeless_eigen.exe'];
% tools(end).run_cmd = tools(end).exe;
% tools(end).ext = 'ADOLC_sparse_tapeless';
% tools(end).col = tools(end-3).col;
% tools(end).marker = markers{4};
% tools(end).call_type = 0;

% tools(end+1).name = 'Adept, R';
% tools(end).exe = [exe_dir,'Adept.exe'];
% tools(end).run_cmd = tools(end).exe;
% tools(end).ext = 'Adept';
% tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
% tools(end).marker = markers{1};
% tools(end).call_type = 0;

% tools(end+1).name = 'Theano';
% tools(end).exe = [python_dir,'Theano/Theano_ba.py'];
% tools(end).run_cmd = ['python.exe ' tools(end).exe];
% tools(end).ext = 'Theano';
% tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
% tools(end).marker = markers{1};
% tools(end).call_type = 1;

% tools(end+1).name = 'Ceres, F';
% tools(end).exe = [exe_dir,'Ceres.exe'];
% tools(end).run_cmd = tools(end).exe;
% tools(end).ext = 'Ceres';
% tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
% tools(end).marker = markers{1};
% tools(end).call_type = 0;

% tools(end+1).name = 'DiffSharp';
% tools(end).exe = [exe_dir,'DiffSharp/DiffSharpTests.exe'];
% tools(end).run_cmd = tools(end).exe;
% tools(end).ext = 'DiffSharp';
% tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
% tools(end).marker = markers{1};
% tools(end).call_type = 0;

% tools(end+1).name = 'DiffSharp, F';
% tools(end).exe = [exe_dir,'DiffSharpF/DiffSharpTests.exe'];
% tools(end).run_cmd = tools(end).exe;
% tools(end).ext = 'DiffSharp_F';
% tools(end).col = tools(end-1).col;
% tools(end).marker = markers{2};
% tools(end).call_type = 0;

% tools(end+1).name = 'Autograd, R';
% tools(end).exe = [python_dir 'Autograd/autograd_ba.py'];
% tools(end).run_cmd = ['python.exe ' tools(end).exe];
% tools(end).ext = 'Autograd';
% tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
% tools(end).marker = markers{1};
% tools(end).call_type = 0;

tools(end+1).name = 'AdiMat, F';
tools(end).exe = 'hand_objective.m';
tools(end).ext = 'adimat';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 3;

tools(end+1).name = 'AdiMat, F (sparse)';
tools(end).exe = 'hand_objective.m';
tools(end).ext = 'adimat_sparse';
tools(end).col = tools(end-1).col;
tools(end).marker = markers{2};
tools(end).call_type = 4;

% tools(end+1).name = 'MuPAD';
% tools(end).exe = 'mupad/mupad_ba_compute_reproj_err_mex.cxx';
% tools(end).ext = 'mupad';
% tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
% tools(end).marker = markers{1};
% tools(end).call_type = 5;

tools(end+1).name = 'Julia, F';
tools(end).exe = [julia_dir 'Tests/hand_F.jl'];
tools(end).run_cmd = ['julia.exe ' tools(end).exe];
tools(end).ext = 'Julia_F';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 0;

