function [times, diffs, types] = admGetTimings(handle, varargin)

  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    adopts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    adopts = admOptions;
    funcArgs = varargin;
  end

  inDCC = adopts.derivClassName;
  
  fName = func2str(handle);
  
  if isfield(adopts, 'x_methods')
    types = adopts.x_methods;
  else
    types = admMethods(adopts);
  end
  
  if isfield(adopts, 'x_tol')
    tol = adopts.x_tol;
  else
    tol = 1e-4; % FD inside
  end

  [types.time] = deal(nan);
  [types.res] = deal({});
  [types.jac] = deal([]);
  [types.hess] = deal([]);
  
  if isfield(adopts, 'x_nTakesTF')
    nTakesTF = adopts.x_nTakesTF;
  else
    nTakesTF = 3;
  end

  fnargout = adopts.nargout;
  if isempty(fnargout)
    fnargout = nargout(handle);
  end
  
  indeps = 1:nargin(handle);
  if ~isempty(adopts.independents)
    indeps = adopts.independents;
  end
  
  deps = 1:fnargout;
  if ~isempty(adopts.dependents)
    deps = adopts.dependents;
  end
  
  [res{1:fnargout}] = handle(funcArgs{:});

  [types.m] = deal(admTotalNumel(res{deps}));
  [types.n] = deal(admTotalNumel(funcArgs{indeps}));
      
  v = rand(types(1).n, 1);
  v_rev = rand(1, types(1).m);
  v_hess = v;

  adopts.functionResults = res;
  adopts.seedRev = ones(1, length(v_rev));

  for k=1:length(types)
    
    switch types(k).name
     case 'fun'
      types(k).desc = 'Function evaluation';
      timesF = zeros(nTakesTF, 1);
      for i=1:nTakesTF
        tic
        [res{1:fnargout}] = handle(funcArgs{:});
        timesF(i) = toc;
      end
      types(k).time = mean(timesF);
      types(k).res = res;
      timeFunc = types(k).time;

    case 'For/O(o)'
     adopts.derivClassName = 'opt_derivclass';
      try
      tic
      [JacFor res{1:fnargout}] = admDiffFor(handle, 1, funcArgs{:}, adopts);
      types(k).time = toc;
      types(k).jac = JacFor;
      types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Jacobian with For (%s)', adimat_derivclass);
      adopts.derivClassName = inDCC;

    case 'For/O(a)'
     adopts.derivClassName = 'arrderivclass';
     try
      tic
        [JacFor res{1:fnargout}] = admDiffFor(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).jac = JacFor;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Jacobian with For (%s)', adimat_derivclass);
      adopts.derivClassName = inDCC;

    case 'For/O(a2)'
     adopts.derivClassName = 'arrderivclassvxdd';
     try
      tic
        [JacFor res{1:fnargout}] = admDiffFor(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).jac = JacFor;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Jacobian with For (%s)', adimat_derivclass);
      adopts.derivClassName = inDCC;

%      spy(JacFor);
%      title('Pattern of J');
%      adopts.JPattern = JacFor ~= 0;

     case 'For/D'
      adopts.derivClassName = 'scalar_directderivs';
      try
        tic
        [JacForD res{1:fnargout}] = admDiffFor(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).jac = JacForD;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      adopts.derivClassName = inDCC;
      types(k).desc = sprintf('Jacobian with For (%s, strip mining)', adimat_derivclass);
    

      
      % types(k).desc = 'Jacobian with For (compression)';
      % tic
      %   JacForC = admDiffFor(handle, @cpr, funcArgs{:}, adopts);
      %   types(k).time = toc
      %   JacForC = full(JacForC); % for norm computation
      % types(k).jac = JacForC;
      
      % types(k).desc = 'Jacobian with For (compression, double derivs, strip mining)';
      % adopts.derivClassName = 'scalar_directderivs';
      % tic
      %   JacForCD = admDiffFor(handle, @cpr, funcArgs{:}, adopts);
      %   types(k).time = toc
      %   JacForCD = full(JacForCD); % for norm computation
      %   adopts.derivClassName = [];
      %   types(k).jac = JacForCD;
      
  case 'For/V'
   try
     tic
     [JacForV res{1:fnargout}] = admDiffFor(handle, v, funcArgs{:}, adopts);
     types(k).time = toc;
     JacForV = full(JacForV); % for norm computation
     types(k).jac = JacForV;
   catch
     warning('mode %s failed: %s', types(k).name, lasterr);
   end
   types(k).desc = sprintf('Jacobian*Vector with For (%s)', adimat_derivclass);

  case 'VFor'
   types(k).desc = 'Jacobian with VFor';
   try
     tic
     [JacVFor res{1:fnargout}] = admDiffVFor(handle, 1, funcArgs{:}, adopts);
     types(k).time = toc;
     types(k).jac = JacVFor;
   catch
     warning('mode %s failed: %s', types(k).name, lasterr);
   end

  case 'VFor/V'
   types(k).desc = 'Jacobian*Vector with VFor';
   try
     tic
     [JacVForV res{1:fnargout}] = admDiffVFor(handle, v, funcArgs{:}, adopts);
     types(k).time = toc;
     JacVForV = full(JacVForV); % for norm computation
     types(k).jac = JacVForV;
   catch
     warning('mode %s failed: %s', types(k).name, lasterr);
   end


     case 'Rev/O(o)'
      adopts.derivClassName = 'opt_derivclass';
      try
        tic
        [JacFor res{1:fnargout}] = admDiffRev(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).jac = JacFor;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Jacobian with Rev (%s)', adimat_derivclass);
      adopts.derivClassName = inDCC;

     case 'Rev/O(a)'
      adopts.derivClassName = 'arrderivclass';
      try
        tic
        [JacFor res{1:fnargout}] = admDiffRev(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).jac = JacFor;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Jacobian with Rev (%s)', adimat_derivclass);
      adopts.derivClassName = inDCC;

     case 'Rev/O(a2)'
      adopts.derivClassName = 'arrderivclassvxdd';
      try
        tic
        [JacFor res{1:fnargout}] = admDiffRev(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).jac = JacFor;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Jacobian with Rev (%s)', adimat_derivclass);
      adopts.derivClassName = inDCC;

     case 'Rev/D'
      adopts.derivClassName = 'scalar_directderivs';
      try
        tic
        [JacForD res{1:fnargout}] = admDiffRev(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).jac = JacForD;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      adopts.derivClassName = inDCC;
      types(k).desc = sprintf('Jacobian with Rev (%s, strip mining)', adimat_derivclass);
    
     case 'Rev/V'
      try
        tic
        [JacForV res{1:fnargout}] = admDiffRev(handle, v_rev, funcArgs{:}, adopts);
        types(k).time = toc;
        JacForV = full(JacForV); % for norm computation
        types(k).jac = JacForV;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Vector*Jacobian with Rev (%s)', adimat_derivclass);


     case 'HRev(a)'
      adopts.derivClassName = 'arrderivclass';
      adopts.hessianStrategy = 't1rev';
      try
        tic
        [H J res{1:fnargout}] = admHessian(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian with Rev');
      adopts.derivClassName = inDCC;

     case 'HRev(a2)'
      adopts.derivClassName = 'arrderivclassvxdd';
      adopts.hessianStrategy = 't1rev';
      try
        tic
        [H J res{1:fnargout}] = admHessian(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian with Rev');
      adopts.derivClassName = inDCC;

     case 'HFor2/O'
      try
        tic
        [H J res{1:fnargout}] = admDiffFor2(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian with For (%s)', adimat_derivclass);
      
     case 'HFor2/D'
      adopts.derivClassName = 'scalar_directderivs';
      try
        tic
        [H J res{1:fnargout}] = admDiffFor2(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      adopts.derivClassName = inDCC;
      types(k).desc = sprintf('Hessian with For (%s)', adimat_derivclass);
      
     case 'HFor(a)'
      adopts.derivClassName = 'arrderivclass';
      adopts.hessianStrategy = 't2for';
      adopts.admDiffFunction = @admTaylorFor;
      try
        tic
        [H J res{1:fnargout}] = admHessian(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian with OO');
      adopts.derivClassName = inDCC;

     case 'HFor(a2)'
      adopts.derivClassName = 'arrderivclassvxdd';
      adopts.hessianStrategy = 't2for';
      adopts.admDiffFunction = @admTaylorFor;
      try
        tic
        [H J res{1:fnargout}] = admHessian(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian with OO');
      adopts.derivClassName = inDCC;

     case 'HVFor'
      adopts.hessianStrategy = 't2for';
      adopts.admDiffFunction = @admTaylorVFor;
      try
        tic
        [H J res{1:fnargout}] = admHessian(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian with VFor');

     case 'HFD'
      adopts.hessianStrategy = 't2for';
      adopts.admDiffFunction = @admDiffFD;
      try
        tic
        [H J res{1:fnargout}] = admHessian(handle, 1, funcArgs{:}, adopts);
        types(k).time = toc;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian with FD');
      types(k).hess = H;
      types(k).jac = J;
      types(k).res = res;


     case 'HRev/V'
      adopts.hessianStrategy = 't1rev';
      try
        tic
        [H J res{1:fnargout}] = admHessian(handle, v_hess, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian*vector with Rev');

     case 'HFor2/V'
      try
        tic
        [H J res{1:fnargout}] = admDiffFor2(@f2, v_hess, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian*vector with For');
      
     case 'HFor/V'
      adopts.hessianStrategy = 't2for';
      adopts.admDiffFunction = @admTaylorFor;
      try
        tic
        [H J res{1:fnargout}] = admHessian(handle, v_hess, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian*vector with OO');

     case 'HVFor/V'
      adopts.hessianStrategy = 't2for';
      adopts.admDiffFunction = @admTaylorVFor;
      try
        tic
        [H J res{1:fnargout}] = admHessian(handle, v_hess, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian*vector with VFor');

     case 'HFD/V'
      adopts.hessianStrategy = 't2for';
      adopts.admDiffFunction = @admDiffFD;
      try
        tic
        [H J res{1:fnargout}] = admHessian(handle, v_hess, funcArgs{:}, adopts);
        types(k).time = toc;
        types(k).hess = H;
        types(k).jac = J;
        types(k).res = res;
      catch
        warning('mode %s failed: %s', types(k).name, lasterr);
      end
      types(k).desc = sprintf('Hessian*vector with FD');

  case 'CS'
   types(k).desc = 'Jacobian with CS method';
   tic
   [JacFD res{1:fnargout}] = admDiffComplex(handle, 1, funcArgs{:}, adopts);
   types(k).time = toc;
   types(k).jac = JacFD;

  case 'CS/V'
   types(k).desc = 'Jacobian*vector with CS method';
   tic
   [JacFD res{1:fnargout}] = admDiffComplex(handle, v, funcArgs{:}, adopts);
   types(k).time = toc;
   types(k).jac = JacFD;

  case 'FD'
   types(k).desc = 'Jacobian with FD';
   tic
   [JacFD res{1:fnargout}] = admDiffFD(handle, 1, funcArgs{:}, adopts);
   types(k).time = toc;
   types(k).jac = JacFD;

  % types(k).desc = 'Jacobian with FD (compression)';
  % tic
  %   JacFDC = admDiffFD(handle, @cpr, funcArgs{:}, adopts);
  %   types(k).time = toc;
  %   JacFDC = full(JacFDC); % for norm computation
  %   types(k).desc = '--------------------------------')
  % types(k).jac = JacFDC;


  case 'FD/V'
   types(k).desc = 'Jacobian*Vector with FD';
   tic
   [JacFDV res{1:fnargout}] = admDiffFD(handle, v, funcArgs{:}, adopts);
   types(k).time = toc;
   JacFDV = full(JacFDV); % for norm computation
   types(k).jac = JacFDV;

   end

   label = sprintf('%s(%s)', types(k).desc, types(k).name);
   fprintf(1, '%s:', label);

   filler = '                                                        ';
   fprintf(1, '%s %g s\n', filler(1:(length(filler) - length(label))), types(k).time);
  end


  names = {types.name};
  times = [types.time];
  jacs = {types.jac};
  hess = {types.hess};
  
  if exist('timeFunc')
    factors = times ./ timeFunc;
    [types.factor] = deal(mat2cell(factors(:), ones(length(factors), 1)));
  end
  
  diffsJ = zeros(length(names)-1);
  diffsH = zeros(length(names)-1);
  isV = [types.isvec];
  
  for i=1:length(names)-1
    a = jacs{i};
    if isempty(a), continue; end
    for j=2:i
      a = jacs{i};
      b = jacs{j};
      if isempty(b), continue; end
      if ~isV(i) && ~isV(j)
      elseif isV(i) && isV(j)
        if isrow(a) && isrow(b)
        elseif iscolumn(a) && iscolumn(b)
        else
          if iscolumn(a)
            a = v_rev * a;
          else
            a = a * v;
          end
          if iscolumn(b)
            b = v_rev * b;
          else
            b = b * v;
          end
        end
      else
        if isV(i)
          if iscolumn(a)
            b = b * v;
          else
            b = v_rev * b;
          end
        else
          if iscolumn(b)
            a = a * v;
          else
            a = v_rev * a;
          end
        end
      end
      diffsJ(i, j) = relMaxNorm(a, b, inf);
    end
  end
  maxErrJ = max(max(diffsJ));

  assert(isempty(maxErrJ) || maxErrJ < tol) % FD inside
  
  for i=1:length(names)-1
    a = hess{i};
    if isempty(a), continue; end
    for j=2:i
      a = hess{i};
      b = hess{j};
      if isempty(b), continue; end
      if (isV(i) && isV(j)) || (~isV(i) && ~isV(j))
      else
        if isV(i)
          b = b * v;
        else
          a = a * v;
        end
      end
      diffsH(i, j) = relMaxNorm(a, b, inf);
    end
  end

  maxErrH = max(max(diffsH));
  assert(isempty(maxErrH) || maxErrH < tol) % FD inside
  
  diffs = {diffsJ, diffsH};
  
  if isfield(adopts, 'x_noplot') && ~adopts.x_noplot(1)
  
if exist('bar3')
  g = figure;
  admSetFigProps(g);
  bar3(-log10(diffs).');
  set(gca, 'xticklabel', names);
  set(gca, 'yticklabel', names);
  title('identical up to this number of digits');
end

end

  if isfield(adopts, 'x_noplot') && ~adopts.x_noplot(2)
    ax = adopts.x_axes(2);
    f = admBarPlot(times, names, 1, 1, ax);
    %xlabel('Method');
    ylabel(ax, 'Time (s)');
    title(ax, sprintf('Run times, %s, $%d\\times %d$ Jacobian', ...
                  fName, length(v_rev), length(v)));

    drawnow;
  end
  
  if isfield(adopts, 'x_noplot') && ~adopts.x_noplot(3)
    ax = adopts.x_axes(3);
    f = admBarPlot(factors, names, 1, 1, ax);
    %xlabel('Method');
    ylabel(ax, 'Ratio $t_\nabla / t_f$');
    title(ax, sprintf('AD factors, %s, $%d\\times %d$ Jacobian', ...
                  fName, length(v_rev), length(v)));
  
    drawnow;
  end

%factors_FD = times ./ tJacFD;
%f = admBarPlot(factors_FD, names);
%xlabel('Method');
%ylabel('Ratio $t_\nabla / t_{\rm FD}$');
%title(sprintf('AD vs. FD factors, %s, $%d\\times %d$ Jacobian, %d Colours', ...
%              fName, size(JacFor, 1), size(JacFor, 2), cpr(JacFor ~= 0)));

% $Id: admGetTimings.m 4412 2014-06-03 15:47:03Z willkomm $
