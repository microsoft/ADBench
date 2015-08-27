function tools = get_tools(exe_dir,python_dir)
% call_type:
%   0 standard - tools(id).run_cmd
%   1 theano - tools(id).run_cmd
%   2 ceres - tools(id).run_cmd+d+k
%   3 adimat
%   4 adimat vectorized
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
        .8 0 .8];
markers = {'none', 's', 'x', '^'};

% tools
tools = {};
unused_col_id = 1;
tools(end+1).name = 'manual, C++';
tools(end).exe = [exe_dir,'Manual_VS.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_manual_VS';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id+1;
tools(end).marker = markers{1};
tools(end).call_type = 0;

tools(end+1).name = 'manual, Eigen';
tools(end).exe = [exe_dir,'Manual_Eigen.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_manual';
tools(end).col = tools(end-1).col;
tools(end).marker = markers{2};
tools(end).call_type = 0;

tools(end+1).name = 'manual, Eigen (vector)';
tools(end).exe = [exe_dir,'Manual_Eigen5.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_manual_Eigen5';
tools(end).col = tools(end-2).col;
tools(end).marker = markers{3};
tools(end).call_type = 0;

tools(end+1).name = 'Tapenade,R';
tools(end).exe = [exe_dir,'Tapenade.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_Tapenade_b';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 0;

tools(end+1).name = 'ADOLC, R';
tools(end).exe = [exe_dir,'ADOLC_full.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_ADOLC';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 0;

tools(end+1).name = 'ADOLC, R (split)';
tools(end).exe = [exe_dir,'ADOLC_split.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_ADOLC_split';
tools(end).col = tools(end-1).col;
tools(end).marker = markers{2};
tools(end).call_type = 0;

tools(end+1).name = 'Adept, R';
tools(end).exe = [exe_dir,'Adept_full.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_Adept';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 0;

tools(end+1).name = 'Adept, R (split)';
tools(end).exe = [exe_dir,'Adept_split.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_Adept_split';
tools(end).col = tools(end-1).col;
tools(end).marker = markers{2};
tools(end).call_type = 0;

tools(end+1).name = 'Theano';
tools(end).exe = [python_dir,'Theano/Theano.py'];
tools(end).run_cmd = ['python.exe ' tools(end).exe];
tools(end).ext = 'J_Theano';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 1;

tools(end+1).name = 'Theano (vector)';
tools(end).exe = [python_dir 'Theano/Theano_vector.py'];
tools(end).run_cmd = ['python.exe ' tools(end).exe];
tools(end).ext = 'J_Theano_vector';
tools(end).col = tools(end-1).col;
tools(end).marker = markers{2};
tools(end).call_type = 1;

tools(end+1).name = 'Ceres, F';
tools(end).exe = [exe_dir,'Ceres/Ceresd2k5.exe'];
tools(end).run_cmd = [exe_dir,'Ceres/Ceres'];
tools(end).ext = 'J_Ceres';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 2;

tools(end+1).name = 'DiffSharp';
tools(end).exe = [exe_dir,'DiffSharpAD/DiffSharpTests.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_diffsharpAD';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 0;

tools(end+1).name = 'DiffSharp, R';
tools(end).exe = [exe_dir,'DiffSharpR/DiffSharpTests.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_diffsharpR';
tools(end).col = tools(end-1).col;
tools(end).marker = markers{2};
tools(end).call_type = 0;

tools(end+1).name = 'DiffSharp, R (split)';
tools(end).exe = [exe_dir,'DiffSharpRSplit/DiffSharpTests.exe'];
tools(end).run_cmd = tools(end).exe;
tools(end).ext = 'J_diffsharpRsplit';
tools(end).col = tools(end-2).col;
tools(end).marker = markers{3};
tools(end).call_type = 0;

tools(end+1).name = 'Autograd, R';
tools(end).exe = [python_dir 'Autograd/autograd_full.py'];
tools(end).run_cmd = ['python.exe ' tools(end).exe];
tools(end).ext = 'J_Autograd';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 0;

tools(end+1).name = 'Autograd, R (split)';
tools(end).exe = [python_dir 'Autograd/autograd_split.py'];
tools(end).run_cmd = ['python.exe ' tools(end).exe];
tools(end).ext = 'J_Autograd_split';
tools(end).col = tools(end-1).col;
tools(end).marker = markers{2};
tools(end).call_type = 0;

tools(end+1).name = 'AdiMat, R';
tools(end).exe = 'gmm_objective.m';
tools(end).ext = 'J_adimat';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 3;

tools(end+1).name = 'AdiMat, R (vector)';
tools(end).exe = 'gmm_objective_vector_repmat.m';
tools(end).ext = 'J_adimat_vector';
tools(end).col = tools(end-1).col;
tools(end).marker = markers{2};
tools(end).call_type = 4;

tools(end+1).name = 'MuPAD';
tools(end).exe = 'awful/matlab/example_gmm_objective_mex_d32_K5.cxx';
tools(end).ext = 'J_mupad';
tools(end).col = cols(unused_col_id,:); unused_col_id = unused_col_id + 1;
tools(end).marker = markers{1};
tools(end).call_type = 5;
