classdef au_optimproblem < handle
  % AU_OPTIMPROBLEM  Simplified but powerful nonlinear least squares
  %       Parameters to be optimized can be any object, e.g. a struct or a
  %       cell or a struct of structs of cells.  It's designed to be
  %       efficient with a few hundred residual blocks, each of 10s to
  %       1000s of parameters.
  %
  %       Finite-difference Jacobians are efficiently computed (maybe of
  %       the order of tens of function evaluations for blocky vision
  %       problems, even for huge numbers of parameters, using the ideas
  %       in [Curtis, Powell, Reid, "On the Estimation of Sparse Jacobian
  %       Matrices", IMA J. Appl. Math. 1972, http://bit.ly/1yYWSUt].
  %       With au_optimproblem, you can save more work by specifying a
  %       cheaply computed overestimate of the sparsity pattern with an
  %       extra line or so of code, which OP.ComputeJacobPattern will
  %       whittle down using a finite difference calculation before
  %       optimization.
  %
  %       It's easy to optimize over only a subset of parameters, so you
  %       can define an objective which parameterizes everything you might
  %       possibly need but then optimize over only a few.  See
  %       OP.ParamsToVary.
  %
  %       See au_optimproblem_test for a tutorial example.  The below is
  %       more for reference.  References to Params<T> mean a structure the
  %       same shape as Params but with contents of type T.
  %
  %       OP = au_optimproblem(Params);  % Construct a problem object
  %
  %       OP.Objective = @(OP) MyFunc(OP, OtherData)
  %       function MyFunc(OP)
  %         OP.ClearResiduals()  % May deprecate if this hurts composition
  %         OP.AddResidualBlock(OP.Params.Pose(i) * OP.Params.Points(j))
  %         OP.AddResidualBlockInfo({OP.Inds.Pose(i), OP.Inds.Points{j}))
  %
  %       Params = P.Optimize();  % Run the optimization
  %
  %       OP.Inds is a Params<int32> which maps from fields in the
  %       structure to parameter indices, such as thse taken by
  %       ParamsToVary, e.g.
  %         OP.ParamsToVary = {OP.Inds.Frame(:).Pose, OP.Inds.Cam1.Focal};
  %
  %       OP.TolX, OP.TolFun, OP.Display, OP.MaxFunEvals, OP.DiffChange
  %          Options like lsqnonlin's
  %       OP.Optimizer
  %          Choose from 'au', 'lsqn_lm', 'lsqn_tr'
  %       OP.LowerBounds, OP.UpperBounds
  %          Bounds like lsqnonlin's but as a Params<double>
  %       OP.DisplayErr
  %          A function handle which takes the residual vector and converts
  %          to a scalar, e.g. to display RMS instead of 2-norm
  %
  %       OP.SaveFile
  %          Name of a file to which to save the best-so-far optimization
  %          parameters in case of error or Ctrl-C
  
  %%
  properties
    Objective
    Params
    Inds
    WantBlockInfo
    
    % Options
    LowerBounds
    UpperBounds
    Display = 'iter' % default is noisy, more experienced callers can turn off
    TolX = 1e-8
    TolFun = 1e-8
    TimeOut = 3600 % 1 Hour
    MaxFunEvals = Inf
    SaveFile = [] % Save current best optimization parameters in case of error/ctrl+C
    Optimizer = 'au'; % au, lsqn_tr, lsqn_lm
    DiffChange = 1e-6;
    UseLineSearch = false;  % Mostly using finite-diff Jacobians, so linmin should be worth it
    DisplayErr = @(e) sum(e.^2); % How to display the error as a scalar
    ResidualsScale = 1
    
    % Progress functions
    OutputFcn = @(OP) []; % Is passed the optimproblem struct.
    
    % Informationals
    Info
    JacobPattern
    Residuals
    nParams
    nResiduals
  end
  
  properties(Dependent)
    ParamsToVary
  end
  
  properties(Access = private)
    ParamsToVary_template
    Residuals_index
    last_residuals_size
    JacobPattern_ij
    start_time
    last_pvec
    do_save_file
    Rebasers % struct: Func, Inds
  end
  
  % Class methods
  methods
    %% Constructor.
    % Create the problem with a Params struct.   It need not be the one
    % you'll use for initial estimate, but it should be the same shape.
    function OP = au_optimproblem(Params, Objective)
      if nargin == 0
        %% Test
        disp('au_optimproblem: You should pass Params. For now, running tests.');
        au_optimproblem_test
        return
      end
      
      OP.Params = Params;
      if nargin > 1
        OP.Objective = Objective;
      end
      OP.nParams = numel(OP.vec(Params));
      zer0 = zeros(OP.nParams,1);
      OP.Inds = au_deep_unvectorize(Params, int32(1:OP.nParams));
      OP.LowerBounds = au_deep_unvectorize_mex(Params, -Inf+zer0);
      OP.UpperBounds = au_deep_unvectorize_mex(Params, +Inf+zer0);
      OP.ParamsToVary_template = au_deep_unvectorize(Params, true(OP.nParams, 1));
      OP.Residuals = [];
      OP.nResiduals = 0;
      OP.Residuals_index = 0;
      OP.last_residuals_size = 0;
      OP.WantBlockInfo = false;
      
      OP.Info.FunCalls = 0;
      OP.Info.Iters = 0;
      OP.Info.FVal = 0;
      OP.Info.log = [-1 -1 -1 -1];
      
    end % double
    
    %% ParamsToVary property.
    %  Assign a Params<logical> to say which params should vary or a
    %  any-shape object containing <int32> which indicate which parameter
    %  indices to vary.   A good source for those is OP.Inds.
    function set.ParamsToVary(OP, val)
      v = au_deep_vectorize(val);
      if islogical(v) 
        au_assert isstruct(val)
        au_assert_equal numel(au_deep_vectorize_mex(val)) OP.nParams
        % Attempt to vectorize val to see if it's all the same type
        v = au_deep_vectorize(val);
        au_assert isa(v(1),'logical')
        OP.ParamsToVary_template = val;
      else
        inds = v;
        if ~isa(inds(1),'int32')
          error('au_optimproblem:ParamsToVary', 'ParamsToVary should be set to int32s.  Use P.Inds?.');
        end
        flags = false(OP.nParams, 1);
        flags(inds) = true;
        OP.ParamsToVary_template = au_deep_unvectorize(OP.Params, flags);
      end
    end
    
    function out = get.ParamsToVary(OP)
      out = OP.ParamsToVary_template;
    end
    
    %% Rebasers are applied to the parameters before each iteration.
    % For example, if Params.Camera1.Rotation is a quaternion, one might
    %   RotInds = {OP.Inds.Camera1.Rotation, OP.Inds.Camera2.Rotation}
    %   OP.AddRebaser(@(x) x/norm(x), RotInds);
    % The second braces ensure that whatever the representation of
    % Each entry is a rebasing function and a cell array of indices.
    % Each cell is a set of indices which pull out a vector of parameters.
    function AddRebaser(OP, Func, Inds)
      OP.Rebasers(end+1).Func = Func;
      for k=1:length(Inds);
        Inds{k} = au_deep_vectorize(Inds{k});
      end
      OP.Rebasers(end).Inds = Inds;
    end
    
    %% Compute which entries of the Jacobian are nonzero.
    % This may take a little while, so is done once before optimization
    % iterations.  Depending how long it takes, you may find you can
    % compute it more rarely, but it can be tricky to precisely decide
    % when it can be avoided, so I would recommend calling it after any
    % change to the objective function or its inputs.  You definitely want
    % to call it if Params changes, or if the number of residuals changes.
    function J_full = ComputeJacobPattern(OP, DEBUG)
      if nargin < 2
        DEBUG = 1;
      end
      
      if DEBUG
        tic
        fprintf('au_optimproblem: get superset JacobPattern...');
      end
      f = @(p) OP.Call(OP.unvec(p));
      
      % Don't compute the JacobPattern at the user-supplied starting point,
      % as it may well be full of zeroes, so add a bit of rand.   It
      % doesn't need to get everything, as we will do more tests during
      % optimization, but it's a good idea to get as much as possible.
      lb = OP.vec(OP.LowerBounds);
      ub = OP.vec(OP.UpperBounds);

      SaveParams = OP.Params;
      p = OP.vec(OP.Params);
      p = p + 0.001*rand(size(p));
      p = min(max(p, lb), ub);
      
      % Compute the superset JacobPattern as supplied by the user's calls
      % to AddResidualBlockInfo, to be refined below.
      OP.WantBlockInfo = true;
      f(p);
      OP.WantBlockInfo = false;
      
      fd_opts = au_opts('FWD=1;timeout=3;tol=1e-4', ...
        struct('delta', OP.DiffChange, 'verbose', DEBUG > 0));
      if ~isempty(OP.JacobPattern_ij)
        ij = cat(1, OP.JacobPattern_ij{:});
        i = double(ij(:,1));
        j = double(ij(:,2));
        JacobPattern_coarse = sparse(i,j, 1, OP.nResiduals, OP.nParams);
        
        ngroups_coarse = max(color_JP(JacobPattern_coarse));
        if DEBUG
          fprintf(' ngroups=%d\n', ngroups_coarse);

          fd_opts.IndToName = @(ind) cal_deep_inds_to_names(OP.Params, ind);
          % Check that JacobPattern with finite differences
          au_check_derivatives(f, p, JacobPattern_coarse, fd_opts, 'PatternOnly=1');
        end
      else
        % User supplied no hints.  Empty is a signal to au_jacobian_fd
        JacobPattern_coarse = [];
        ngroups_coarse = Inf;
      end
      
      % Refine JacobPattern
      if DEBUG
        fprintf('au_optimproblem: get finite-diff Jacobian...');
      end
      J_full = au_jacobian_fd(f, p, JacobPattern_coarse, OP.DiffChange);
      if DEBUG
        fprintf('%dx%d nnz = %d, time = %.1f sec\n', size(J_full), nnz(J_full), toc);
      end
      
      au_check_derivatives(f, p, J_full, fd_opts);
      
      OP.JacobPattern = J_full ~= 0;
      ngroups = max(color_JP(OP.JacobPattern));
      
      if DEBUG
        fprintf('au_optimproblem: refined ngroups/coarse/params=%d/%d/%d\n', ...
          ngroups, ngroups_coarse, OP.nParams);

        if DEBUG > 1
          fprintf('au_optimproblem: Computing full FD jacobian\n');
          J_total = au_jacobian_fd(f, p, [], OP.DiffChange);
          J_total = J_total ~= 0;
        else
          J_total = J_full;
        end
        
        if DEBUG > 1
          clf
          [fi,fj] = find(J_total & ~JacobPattern_coarse);
          plot(fj,fi,'r.', 'DisplayName', 'Bad: Coarse said no');
          hold on
          [fi,fj] = find(J_total & JacobPattern_coarse);
          plot(fj,fi,'.', 'markersize', 6, 'color', [0 .6 0], 'DisplayName', 'Good: Coarse=Full');
          [fi,fj] = find(~J_total & JacobPattern_coarse);
          plot(fj,fi,'k.', 'markersize', 3, 'DisplayName', 'OK: Coarse overestimated');
          
          empty_cols = find(sum(J_total, 1) == 0);
          if 0
            plot(empty_cols*[1 1], [1 OP.nResiduals], 'm-', ...
              'DisplayName', 'Empty column');
          end
          legend(findobj(gca, 'type', 'line'));
          axis ij
          axis([.5 OP.nParams+.5 .5 OP.nResiduals+.5]);
          title(sprintf('Empty cols: %d, refined ngroups/coarse/params=%d/%d/%d.', ...
            numel(empty_cols), ngroups, ngroups_coarse, OP.nParams));
        end
      end
      
      OP.Params = SaveParams;
    end
    
    %% Reset residuals accumulators for a new objective calculation
    function ClearResiduals(OP)
      % Maintain size of array so that we don't pay to grow it every time
      if (size(OP.Residuals,1) ~= OP.nResiduals)
        OP.Residuals = zeros(OP.nResiduals,1);
      end
      OP.Residuals_index = 0;
      OP.last_residuals_size = [];
      OP.JacobPattern_ij = {};
    end
    
    %% Add a block of residuals to the current objective calculation
    % Optional argument USED_PARAMS calls AddResidualBlockInfo (see below).
    function AddResidualBlock(OP, residuals, used_params)
      % If we ever want to parallelize this, we'll need to get callers to
      % supply a block ID, because they need to be added in a consistent
      % order for each iteration.
      % i.e. don't worry about the race when these next two methods
      % are called sequentially, as running them in parallel needs other
      % work too.
      n = numel(residuals);
      OP.last_residuals_size = n;
      inds = OP.Residuals_index + (1:n);
      OP.Residuals(inds) = OP.ResidualsScale * residuals(:);
      OP.nResiduals = max(OP.nResiduals, numel(OP.Residuals));
      OP.Residuals_index = OP.Residuals_index + n;
      if OP.WantBlockInfo && nargin > 2 % ordered for speed
        OP.AddResidualBlockInfo(used_params);
      end
    end
    
    %% Say which parameters were used to compute a block of residuals.
    % You need not be super-refined with this, for example each individual
    % residual in a block may depend on only a subset of parameters in a
    % block, but you can just say that all the residuals depend on all the
    % parameters.
    % If you don't supply this, or are unrefined, the outcome will be
    % increased time to ComputeJacobPattern.  Depending on how often you
    % need to do that, it may or may not be worth your while.
    function AddResidualBlockInfo(OP, used_params)
      n = OP.last_residuals_size;
      JP_rows = int32(OP.Residuals_index - n + (1:n)');
      JP_cols = au_deep_vectorize(used_params);
      if any(JP_cols ~= round(JP_cols)) || any(JP_cols < 1)
        error('au_optimproblem:BadInfo', 'Non-integer in inds');
      end
      [ii,jj] = meshgrid(JP_rows, JP_cols);
      OP.JacobPattern_ij{end+1} = [ii(:) jj(:)];
    end
    
    %% Run optimization
    function outParams = Optimize(OP, Params)
      if nargin > 1
        OP.Params = Params;
      end
      
      lb = OP.vec(OP.LowerBounds);
      ub = OP.vec(OP.UpperBounds);
      
      if isempty(OP.JacobPattern)
        OP.ComputeJacobPattern();
      end
      
      % lsqnonlin will see only a subset of parameters.
      p_init = au_deep_vectorize_mex(OP.Params);
      p_varying_mask = au_deep_vectorize(OP.ParamsToVary_template);
      
      pvec = p_init(p_varying_mask);
      lb = lb(p_varying_mask);
      ub = ub(p_varying_mask);
      
      subset_JacobPattern = OP.JacobPattern(:,p_varying_mask);
      
      p2all = @(x) masked_assign(p_init, p_varying_mask, x);
      
      au_assert_equal p2all(p_init(p_varying_mask)) p_init
      
      f = @(x) OP.CallWithSubset(x, p2all, subset_JacobPattern);
      
      res0 = f(pvec);
      au_assert_equal numel(res0) size(subset_JacobPattern,1)
      
      if ~strcmp(OP.Display, 'none')
        fprintf('au_optimproblem: Begin, nParams = %d/%d, nResiduals = %d, nGroups = %d, Err = %8.3e [%g]\n', ...
          numel(pvec), OP.nParams, OP.nResiduals, max(color_JP(subset_JacobPattern)), ...
          norm(res0)^2, OP.DisplayErr(res0/OP.ResidualsScale));
      end
      
      OP.last_pvec = pvec;
      OP.do_save_file = true;
      sentinel = onCleanup(@() OP.Cleanup(p2all));
      OP.start_time = clock;
      
      switch OP.Optimizer
        case {'lsqn_lm', 'lsqn_tr'}
          %% Call lsqnonlin
          if ~isempty(OP.Rebasers)
            error('au_optimproblem:Rebasers', ...
              'OP.Optimizer set to lsq*, does not support rebasers');
          end
          opts = optimset('lsqnonlin');
          opts.Display = 'none';
          opts.MaxFunEvals = min(OP.MaxFunEvals, 1e6);
          opts.TolFun = OP.TolFun;
          opts.TolX = OP.TolX;
          opts.OutputFcn = @(x,opt,state) OP.OutputFcn_lsqnonlin(x, opt, state);
          USE_LM = strcmp(OP.Optimizer, 'lsqn_lm');
          if USE_LM
            opts.Jacobian = 'on';
            opts.Algorithm = 'levenberg-marquardt';
          end
          
          %   [X,RESNORM,RESIDUAL,EXITFLAG] = LSQNONLIN(FUN,X0,...) returns an
          %   EXITFLAG that describes the exit condition of LSQNONLIN. Possible
          %   values of EXITFLAG and the corresponding exit conditions are listed
          %   below. See the documentation for a complete description.
          %
          msgs = {
            1,  'LSQNONLIN converged to a solution.'
            2,  'Change in X < TolX.'
            3,  'Change in f < TolFun.'
            4,  'Computed search direction too small.'
            0,  'Too many function evaluations or iterations.'
            -1,  'Stopped by output/plot function.'
            -2,  'Bounds are inconsistent.'
            };
          %   [X,RESNORM,RESIDUAL,EXITFLAG,OUTPUT] = LSQNONLIN(FUN,X0,...) returns a
          %   structure OUTPUT with the number of iterations taken in
          %   OUTPUT.iterations, the number of function evaluations in
          %   OUTPUT.funcCount, the algorithm used in OUTPUT.algorithm, the number
          %   of CG iterations (if used) in OUTPUT.cgiterations, the first-order
          %   optimality (if used) in OUTPUT.firstorderopt, and the exit message in
          %   OUTPUT.message.
          %
          
          [pvec, ~, res, exitflag, output] = lsqnonlin(f, pvec, lb, ub, opts);
          
          if strcmp(OP.Display, 'final')
            msgid = (exitflag == au_deep_vectorize(msgs(:,1)));
            au_assert_equal sum(msgid) 1
            msg = msgs(msgid,2);
            rms0 = OP.DisplayErr(res0/OP.ResidualsScale);
            rms = OP.DisplayErr(res/OP.ResidualsScale);
            fprintf('au_optimproblem: RMS start/end %g/%g [%g/%g], iters %d, time %.1fsec, [%s]\n', ...
              norm(res0)^2, norm(res)^2, rms0, rms, output.iterations, etime(clock, OP.start_time), msg{1});
          end
          
        case 'au'
          %% Call au_levmarq
          opts = au_levmarq('opts');
          opts.MaxIter = Inf;      % Maximum number of outer iterations
          opts.MaxFunEvals = OP.MaxFunEvals;  % Maximum numbre of function calls
          opts.TimeOut = OP.TimeOut;      % Timeout in seconds
          opts.Display = OP.Display;   % Verbosity: none, final, final+, iter
          opts.CHECK_JACOBIAN = .2; % 200msec
          opts.DiffChange = OP.DiffChange;
          opts.USE_LINMIN = OP.UseLineSearch;     % Use a line search?
          %opts.SCHUR_SPLIT = 0;    % Use Schur decompostion.
          % If n = opts.SCHUR_SPLIT, and J = [A B]
          % with cols(A) = n, then assume B'*B
          % is fast to invert using pcg.
          %opts.USE_JTJ = 1;        % Form J'*J before solving
          %opts.DECOMP_LU = 0;      % 1: backslash, 0: PCG
          
          % Function called each time f is evaluated.
          opts.InnerIterFcn = @(x) [];
          
          % Function called before each outer iteration,
          % just before f is called again.
          % It is passed x, and may modify it before returning,
          % E.g. to re-center.
          opts.IterStartFcn = @(x) OP.CallRebasers(x, p_varying_mask);
          
          % Function called after each reduction in f,
          opts.PlotFcn = @(varargin) OP.OutputFcn_au(varargin{:});
          
          % How to display the scalar error
          opts.DisplayErr = OP.DisplayErr;
          
          % Levenberg-Marquardt parameters.
          opts.LAMBDA_MIN = 1e-12;
          opts.LAMBDA_DECREASE = 2;
          opts.LAMBDA_MAX = 1e8;
          opts.LAMBDA_INCREASE_BASE = 10;
          
          opts.TolFun = OP.TolFun;
          
          OP.Info.FunCalls = 0;
          OP.Info.Iters = 0;
          [pvec, fval, log, endmsg] = au_levmarq(pvec, f, opts);
          %
          %terminated = endmsg(1) ~= '>';
          OP.Info.log = [OP.Info.log; -1 -1 -1 -1; log];
          OP.Info.Iters = size(log,1);
          %OP.Info.FunCalls = log(end,4);
          OP.Info.LM_Lambda = log(end,1);
          OP.Info.FVal = fval;
          OP.Info.EndMessage = endmsg;
          
        otherwise
          error('au_optimproblem:Optimizer', 'Bad optimizer [%s]', OP.Optimizer);
      end
      
      OP.Params = OP.unvec(p2all(pvec));
      outParams = OP.Params;
      % Normal exit, don't save the params
      OP.do_save_file = false;
    end
    
    %% Call this to inspect Jacobian nullspace
    function DebugJacobianNullvector(OP, J, k)
      if numel(J) > 1e8
        keyboard; % SVD might hang...
      end
      p_init = au_deep_vectorize_mex(OP.Params);
      p_varying_mask = au_deep_vectorize(OP.ParamsToVary_template);
      p_fixed_mask = ~p_varying_mask;
      [~,S,V] = svd(full(J));
      semilogy(diag(S),'.-');
      nv = V(:,end-k+1);
      nv = cal_incorporate_fixed_params(p_init*0,p_fixed_mask,nv);
      nv_int = round(nv/max(abs(nv))*99);
      pr(OP.unvec(nv_int));
    end
    
    %% Call rebasers
    function x = CallRebasers(OP, x, p_subset_mask)
      p_subset_inds = cumsum(p_subset_mask);
      for k=1:length(OP.Rebasers)
        Rebaser = OP.Rebasers(k);
        Func = Rebaser.Func;
        for j=1:length(Rebaser.Inds)
          i = Rebaser.Inds{j};
          active = p_subset_mask(i);
          au_assert all(active)||~any(active)
          if all(active)
            i_subset = p_subset_inds(i);
            x(i_subset) = Func(x(i_subset));
          end
        end
      end
    end
    
    %% Cleanup function -- see SaveFile
    function Cleanup(OP, p2all)
      if OP.do_save_file && ~isempty(OP.SaveFile)
        fprintf('au_optimproblem: Saving state to [%s]\n', OP.SaveFile);
        tmpParams = OP.unvec(p2all(OP.last_pvec));
        save(OP.SaveFile, 'tmpParams');
      end
    end
    
    %% OutputFunction for lsqnonlin
    function stop = OutputFcn_lsqnonlin(OP, pvec, opt, state)
      t = etime(clock, OP.start_time);
      stop = t > OP.TimeOut;
      switch state
        case 'interrupt'
        otherwise
          if ~isempty(OP.SaveFile)
            OP.last_pvec = pvec;
          end
          OP.Info.Iters = opt.iteration;
          OP.Info.FunCalls = opt.funccount;
          OP.Info.LM_Lambda = opt.lambda;
          OP.Info.FVal = opt.resnorm;
          OP.OutputFcn();
          if strcmp(OP.Display, 'iter')
            % [~,s] = cal_view_2(Params, data, [], [], 'rms');
            fprintf('it%3d %5.1fs f %.8e [%7.2frms], [%s]\n', ...
              opt.iteration, t, opt.resnorm, sqrt(opt.resnorm/OP.nResiduals), state);
          end
      end
    end
    %% OutputFunction for au_levmarq
    function stop = OutputFcn_au(OP, pvec, fval, iter, lambda)
      t = etime(clock, OP.start_time);
      stop = t > OP.TimeOut;
      if ~isempty(OP.SaveFile)
        OP.last_pvec = pvec;
      end
      OP.Info.Iters = iter;
      OP.Info.LM_Lambda = lambda;
      OP.Info.FVal = fval;
      OP.OutputFcn();
      %       if strcmp(OP.Display, 'iter')
      %         % [~,s] = cal_view_2(Params, data, [], [], 'rms');
      %         fprintf('it%3d %5.1fs f %.8e [%7.2frms], [%s]\n', ...
      %           opt.iteration, t, opt.resnorm, sqrt(opt.resnorm/OP.nResiduals), state);
      %       end
    end
    
    %% Call with a parameter vector
    function residuals = Call(OP, Params)
      if isempty(OP.Objective)
        error('au_optimproblem:NoObjective', 'Need to set OP.Objective');
      end
      OP.Info.FunCalls = OP.Info.FunCalls+1;
      OP.Params = Params;
      OP.ClearResiduals();
      OP.Objective(OP);
      residuals = OP.Residuals(:);
    end
    
    %% Call with only the parameters in ParamsToVary
    function [residuals, Jacobian] = CallWithSubset(OP, p_subset, p2all, subset_JacobPattern)
      residuals = OP.Call(OP.unvec(p2all(p_subset)));
      
      if nargout > 1
        f = @(p) OP.Call(OP.unvec(p2all(p)));
        Jacobian = au_jacobian_fd(f, p_subset, subset_JacobPattern, OP.DiffChange);
      end
    end
    
    %% Override display method
    function disp(OP)
      if isempty(OP.Params)
        fprintf('au_optimproblem [EMPTY]\n');
      else
        fprintf('au_optimproblem: nResiduals %d, nParams %d, vary %d\n', ...
          OP.nResiduals, OP.nParams, sum(au_deep_vectorize(OP.ParamsToVary)));
        p = @(x) fprintf(' %s=%s\n', x, mat2str(OP.(x)));
        %p('LowerBounds');
        %p('UpperBounds');
        fprintf(' Objective='); disp(OP.Objective);
        p('Display');
        p('TolX');
        p('TolFun');
        p('TimeOut'); % 1 Hour
        p('MaxFunEvals');
        p('SaveFile'); % Save current best optimization parameters in case of error/ctrl+C
        p('Optimizer'); % au, lsqn_tr, lsqn_lm
        p('DiffChange');
        p('UseLineSearch');  % Mostly using finite-diff Jacobians, so linmin should be worth it
      end
    end
    
    %% Vectorize
    function v = vec(~, P)
      v = au_deep_vectorize_mex(P);
    end
    
    %% Unvectorize
    function P = unvec(OP, x)
      if isa(x, 'double')
        P = au_deep_unvectorize_mex(OP.Params, x);
      else
        P = au_deep_unvectorize(OP.Params, x);
      end
    end
  end
end

%% Compute graph coloring for finite-difference calculation
function c = color_JP(JacobPattern)
n = size(JacobPattern, 2);
p = colamd(JacobPattern)';
p = (n+1)*ones(n,1)-p;
c = color(JacobPattern,p);
end

%% Assign a subset of array elements
function a = masked_assign(a, mask, vals)
a(mask) = vals;
end
