classdef tseries

properties
  m_series
  m_ord
end

methods(Static)
function r = option(name, val)
  persistent options
  if nargin < 2
    switch name
     case 'options'
      r = options;
     case 'maxorder'
      r = options.ord;
     case 'inner'
      r = options.inner;
     case {'DerivativeClassVersion'}
      r = 0.111;
     case {'DerivativeClassName'}
      r = 'tseries';
     case {'DerivativeClassKind'}
      r = 'tseries';
     otherwise
      error('unknown field %s', name);
    end
  else
    switch name
     case {'maxorder'}
      options.ord = val;
     case {'inner'}
      options.inner = val;
    end
  end
end

end

methods

function obj = tseries(val,type)
  if nargin < 1
    obj.m_ord = 0;
  else
  if isa(val, 'struct')
    if val.m_ord > 1 && isstruct(val.m_series{2})
      func = str2func(val.m_series{2}.className);
      val.m_series(2:end) = cellfun(func, val.m_series(2:end), 'uniformoutput', false);
    end
    obj.m_ord = val.m_ord;
    obj.m_series = val.m_series;
  elseif isa(val, 'tseries')
    obj = val;
    switch type
     case 'zeros'
      for k=1:obj.m_ord
        obj.m_series{k}(:) = 0;
      end
    end
  else
    opts = tseries.option('options');
    obj.m_ord = opts.ord+1;
    inner = opts.inner;
    iv = inner(zeros(size(val)));
    obj.m_series = cell([obj.m_ord, 1]);
    obj.m_series{1} = val;
    [obj.m_series{2:end}] = deal(iv);
  end
  end
end

function val = get(obj, name)
  val = tseries.option(name);
end

function obj = set(obj, name, val)
  tseries.option(name, val);
end
function obj = conj(obj)
  obj = unop(obj, @conj);
end
function res = toStruct(obj)
  res.m_series = obj.m_series;
  res.m_ord = obj.m_ord;
  if res.m_ord > 1 && isobject(res.m_series{2})
    res.m_series(2:end) = cellfun(@toStruct, res.m_series(2:end), 'uniformoutput', false);
  end
  res.adimat_cname = 'tseries';
end
function obj = cumsum(obj, varargin)
  obj = unopV(obj, @cumsum, varargin{:});
end
function [obj, mi] = max1(obj)
  [mv, mi] = max(obj.m_series{1});
  for i=1:obj.m_ord
    obj.m_series{i} = obj.m_series{i}(mi);
  end
end
function obj = atan(obj)
  obj = 0.5 .* i .* log( (1 - i.*obj) ./ (1 + i.*obj) );
end
function obj = diff(obj, varargin)
  obj = adimat_diff(obj, varargin{:});
end
function obj = power(obj, right)
  if ~isa(right, 'tseries') && mod(right, 1) == 0
    % power of integers
    % computed by squaring method: is slower
    xs = obj;
    xp = tseries(ones(size(obj)));
    while right >= 1
      if mod(right, 2) == 1
        xp = xp .* xs;
      end
      xs = xs .* xs;
      right = floor(right ./ 2);
    end
    obj = xp;
  else
    obj = exp(right .* log(obj));
  end
end
function obj = csch(obj)
  [obj] = sinhcosh(obj);
  obj = 1 ./ obj;
end
function obj = dot(obj, right, varargin)
  obj = sum(obj .* right, varargin{:});
function obj = unopc(obj, handle, varargin)
  obj = unopV(obj, handle, varargin{:});
end
function res = ne(obj, v)
  res = cmpop(obj, v, @ne);
end
function [obj] = cumtrapz(varargin)
  obj = adimat_cumtrapz(varargin{:});
end
function obj = vertcat(obj, varargin)
  obj = cat(1, obj, varargin{:});
end
function res = mldivide_square(obj, right)
  [m n] = size(obj);
  opts = struct();
  if m ~= n
    opts.RECT = true;
  end
  res = linsolve_square(obj, right, opts);
end
function obj = tanh(obj)
  [sh, ch] = sinhcosh(obj);
  obj = sh ./ ch;
end
function obj = asin(obj)
  obj = -i .* log( i.*obj + sqrt(1 - obj.^2) );
end
function last = end(obj, k, n)
  sz = size(obj.m_series{1});
  if k == n
    if k == 1
      last = prod(sz);
    else
      d = length(sz);
      last = prod(sz(k:d));
    end
  else
    last = sz(k);
  end
end
function r = ismatrix(obj)
  r = ismatrix(obj.m_series{1});
end
function [obj] = prod(obj, k)
  if nargin == 2
    obj = adimat_prod2(obj, k);
  else
    obj = adimat_prod1(obj);
  end
end
function res = numel(obj, varargin)
%  fprintf('tseries.numel: %s\n', num2str(size(obj)));
%  disp(varargin);
  if nargin < 2
    res = prod(size(obj));
    return
  end
  if ischar(varargin{1}) && varargin{1}==':'
    res = obj.m_ord(1);
  else
    res = length(varargin{1});
  end
%  fprintf('tseries.numel: %d\n', res);
end
function r = isvector(obj)
  r = isvector(obj.m_series{1});
end
function [obj, mi] = max(obj, right)
  if nargin == 1
    [obj, mi] = max1(obj);
  elseif nargin == 2
    [obj] = max2(obj, right);
  end
end
function obj = cat(dim, varargin)
  nempty = cellfun('isempty', varargin);
  ins = varargin(~nempty);
  d_cells = cell(length(ins),1);
  for k=1:length(ins)
    if ~isa(ins{k}, 'tseries')
      ins{k} = tseries(ins{k});
    end
    d_cells{k} = ins{k}.m_series;
  end
  obj = ins{1};
  obj.m_series = cellfun(@(varargin) cat(dim, varargin{:}), d_cells{:}, 'UniformOutput', false);
end
function val = toDouble(obj)
  nsz = [1 size(toDouble(obj.m_series{1}))];
  vals = cellfun(@(x) reshape(toDouble(x), nsz), obj.m_series, 'UniformOutput', false);
  val = cat(1, vals{:});
end
function obj = sin(obj)
  [obj] = sincos(obj);
end
function TCs = coeffs(obj, maxOrder)
  if nargin < 2
    maxOrder = obj.m_ord-1;
  end
  nx = numel(obj.m_series{1});
  TCs = zeros(nx, maxOrder);
  for o=1:maxOrder
    TCs(:, o) = obj.m_series{o+1}(:);
  end
  TCs = reshape(TCs, [size(obj.m_series{1}) maxOrder]);
function obj = det(obj)
  if obj.m_ord > 2
    error('adimat:tseries:det:unsupportedOrder', ...
          ['Taylor coefficients of the function det are only supported ' ...
           'up to first order, but the maximum order is set to %d'], ...
          obj.m_ord -1);
  end
  Ainv = inv(obj.m_series{1});
  Adet = det(obj.m_series{1});
  obj.m_series{1} = Adet;
  obj.m_series{2} = Adet * trace(Ainv * obj.m_series{2});
end
function obj = unopV(obj, handle, varargin)
  for k=1:obj.m_ord
    obj.m_series{k} = handle(obj.m_series{k}, varargin{:});
  end
end
function obj = atanh(obj)
  obj = 0.5 .* log((1 + obj) ./ (1 - obj));
end
function obj = sqrt(obj)
  eT = obj.m_series;
  eT{1} = sqrt(obj.m_series{1});
  eT12 = 2 .* eT{1};

  eT{2} = obj.m_series{2} ./ eT12;
  
  for k=3:obj.m_ord
    eT{k} = -eT{k-1} .* eT{2};
    for j=3:k-1
      eT{k} = eT{k} - eT{k-j+1} .* eT{j};
    end
    eT{k} = eT{k} + obj.m_series{k};
    eT{k} = eT{k} ./ eT12;
  end
  obj.m_series = eT;
end
function obj = times(obj, right)
  if isa(obj, 'tseries')
    if isa(right, 'tseries')
      for k=obj.m_ord:-1:1
        s = obj.m_series{1} .* right.m_series{k};
        for i=2:k
          s = s + obj.m_series{i} .* right.m_series{k-i+1};
        end
        obj.m_series{k} = s;
      end
    else
      for k=1:obj.m_ord
        obj.m_series{k} = obj.m_series{k} .* right;
      end
    end
  else
    val = obj;
    obj = right;
    for k=1:obj.m_ord
      obj.m_series{k} = val .* obj.m_series{k};
    end
  end
end
function obj = sparse(obj)
  obj = unopc(obj, @sparse);
end
function obj = call(handle, obj)
  obj.m_series{1} = handle(obj.m_series{1});
  obj.m_series(2:end) = cellfun(@(x) call(handle, x), obj.m_series(2:end), 'UniformOutput', false);
end
% function [t, y_obj] = ode23t(func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode23t(func, ts, y0)
  [t, y_obj] = ode_generic(@ode23t, func, ts, y0);
function obj = imag(obj)
  obj = unop(obj, @imag);
end
function obj = full(obj)
  obj = unopc(obj, @full);
end
function obj = tan(obj)
  [s, c] = sincos(obj);
  obj = s ./ c;
end
function r = norm(obj, varargin)
  if nargin < 2
    p = 2;
  else
    p = varargin{1};
  end
  r = adimat_norm2(obj, p);
end
function disp(obj)
  fprintf('Taylor series of order %d of size %s\n', obj.m_ord, mat2str(size(obj)));
  for i=1:obj.m_ord
    fprintf('Coefficients of order %d:\n', i-1);
    disp(obj.m_series{i});
  end
end
function [obj] = max2(obj, right)
  if isscalar(obj)
    szr = size(right);
    obj = repmat(obj, szr);
  end
  if isa(obj, 'tseries')
    if isa(right, 'tseries')
      ll = obj.m_series{1} < right.m_series{1};
      for i=1:obj.m_ord
        obj.m_series{i}(ll) = right.m_series{i}(ll);
      end
    else
      ll = obj.m_series{1} < right;
      obj.m_series{1}(ll) = right;
      for i=2:obj.m_ord
        obj.m_series{i}(ll) = 0;
      end
    end
  else
    ll = obj < right.m_series{1};
    obj = tseries(obj);
    for i=1:obj.m_ord
      obj.m_series{i}(ll) = right.m_series{i}(ll);
    end
  end
end
function [sobj, cobj] = sinhcosh(obj)
  sT = obj.m_series;
  cT = obj.m_series;
  sT{1} = sinh(obj.m_series{1});
  cT{1} = cosh(obj.m_series{1});
  for j=1:obj.m_ord-1
    sT{j+1} = zeros(size(sT{j+1}));
    cT{j+1} = zeros(size(cT{j+1}));
    for i=0:j-1
      sT{j+1} = sT{j+1} + ((j-i)/j) .* cT{i+1} .* obj.m_series{j-i+1};
      cT{j+1} = cT{j+1} + ((j-i)/j) .* sT{i+1} .* obj.m_series{j-i+1};
    end
  end
  sobj = obj;
  cobj = obj;
  sobj.m_series = sT;
  cobj.m_series = cT;
end
function [varargout] = eig(a)
  assert(a.m_ord == 2, 'The eig methods supports first order derivatives only');
  if nargout == 1
    [V, D] = eig(a.m_series{1});
    l = tseries(diag(D));
    l.m_series{2} = call(@diag, V \ (a.m_series{2} * V));
    varargout = {l};
  elseif nargout == 2
    [V, D] = eig(a.m_series{1});
    tmp = V \ (a.m_series{2} * V);
    tV = tseries(V);
    tD = tseries(D);
    tD.m_series{2} = call(@diag, call(@diag, tmp));
    tV.m_series{2} = V * (d_eig_F(diag(D)) .* tmp);
    varargout = {tV tD};
  end
end
% $Id: eig.m 4977 2015-05-08 10:21:53Z willkomm $
function obj = uplus(obj)
  obj = unop(obj, @uplus);
end
function obj = subsasgn(obj, ind, rhs)
  switch ind(1).type
   case '()'
    if isa(rhs, 'tseries')
      if isa(obj, 'double')
        obj = tseries(obj, rhs.m_ord-1);
      end
      for k=1:obj.m_ord
        obj.m_series{k} = subsasgn(obj.m_series{k}, ind, rhs.m_series{k});
      end
    else
      obj.m_series = cellfun(@(x, y) subsasgn(x, ind, 0), obj.m_series, 'UniformOutput', false);
      obj.m_series{1} = subsasgn(obj.m_series{1}, ind, rhs);
    end
   case '{}'
    ind1 = ind(1).subs;
    if isa(rhs, 'tseries')
      if length(ind) > 1
        obj.m_series(ind1{:}) = cellfun(@(x, y) subsasgn(x, ind(2:end), y), obj.m_series(ind1{:}), rhs.m_series, 'UniformOutput', false);
      else
        obj.m_series(ind1{:}) = rhs.m_series;
      end
    else
      if length(ind) > 1
        obj.m_series(ind1{:}) = cellfun(@(x) subsasgn(x, ind(2:end), rhs), ...
                                        obj.m_series(ind1{:}), 'UniformOutput', false);
      else
        csz = size(obj);
        rsz = size(rhs);
        if ~isequal(csz, rsz)
          error('adimat:tseries:subsasgn:sizeMismatch', ...
                ['when setting a taylor coefficient, the size must ' ...
                 'be the same as the current size (%s), but it is %s'], ...
                mat2str(csz), mat2str(rsz));
        end
%        inner = tseries.option('inner');
%        rhsv = inner(rhs);
        obj.m_series{ind1{:}} = rhs;
      end
    end
  end
end
function obj = binop(obj, right, handle)
  if isa(obj, 'tseries')
    if isa(right, 'tseries')
      obj.m_series = cellfun(handle, obj.m_series, right.m_series, 'UniformOutput', false);
    else
      obj.m_series = cellfun(@(x) handle(x, right), obj.m_series, 'UniformOutput', false);
    end
  else
    val = obj;
    obj = right;
    obj.m_series = cellfun(@(y) handle(val, y), right.m_series, 'UniformOutput', false);
  end
end
function obj = csc(obj)
  [obj] = sincos(obj);
  obj = 1 ./ obj;
end
function [varargout] = size(obj, varargin)
  arg2str = '';
  if length(varargin) > 0
    arg2str = [', ' num2str(varargin{1})];
  end
  if length(obj.m_series) > 0
%    fprintf('size(x%s): %s\n', arg2str, num2str(size(obj.m_series{1}, varargin{:})));
    [varargout{1:nargout}] = size(obj.m_series{1}, varargin{:});
  else
    warning('empty taylor object inquired');
    if nargout == 1
      [varargout{1}] = [0 0];
    else
      [varargout{1:nargout}] = deal(0);
    end
  end
end
function res = lt(obj, v)
  res = cmpop(obj, v, @lt);
end
function z = deval(obj, h, maxorder)
  if nargin < 3
    maxorder = obj.m_ord-1;
  end
  TCs = coeffs(obj, maxorder);
  nx = numel(obj.m_series{1});
  terms = bsxfun(@times, reshape(TCs, nx, []), h.^(1:maxorder));
  z = reshape(sum(terms, 2), size(obj.m_series{1}));
function res = gt(obj, v)
  res = cmpop(obj, v, @gt);
end
function errors = errors(obj, h)
  TCs_top = obj.m_series{obj.m_ord};
  errors = abs(TCs_top) .* h.^(obj.m_ord-1);
function obj = acsc(obj)
  obj = asin(1 ./ obj);
end
function [q r] = qr(obj)
  [q r] = adimat_qr(obj);
end
function obj = ipermute(obj, order)
  obj = unopV(obj, @ipermute, order);
end
function obj = inv(obj)
  if obj.m_ord > 2
    error('adimat:tseries:inv:unsupportedOrder', ...
          ['Taylor coefficients of the function inv are only supported ' ...
           'up to first order, but the maximum order is set to %d'], ...
          obj.m_ord -1);
  end
  Ainv = inv(obj.m_series{1});
  obj.m_series{1} = Ainv;
  obj.m_series{2} = - Ainv * obj.m_series{2} * Ainv;
end
function obj = ctranspose(obj)
  obj = unop(obj, @ctranspose);
end
function obj = acot(obj)
  obj = atan(1 ./ obj);
end
function obj = cross(obj, right, varargin)
  if isa(obj, 'tseries')
    if isa(right, 'tseries')
      for k=obj.m_ord:-1:1
        s = cross(obj.m_series{1}, right.m_series{k}, varargin{:});
        for i=2:k
          s = s + cross(obj.m_series{i}, right.m_series{k-i+1}, varargin{:});
        end
        obj.m_series{k} = s;
      end
    else
      for k=1:obj.m_ord
        obj.m_series{k} = cross(obj.m_series{k}, right, varargin{:});
      end
    end
  else
    val = obj;
    obj = right;
    for k=1:obj.m_ord
      obj.m_series{k} = cross(val, obj.m_series{k}, varargin{:});
    end
  end
function r = isscalar(obj)
  r = isscalar(obj.m_series{1});
end
function obj = reshape(obj, varargin)
  obj.m_series = cellfun(@(x) reshape(x, varargin{:}), obj.m_series, ...
                         'UniformOutput', false);
end
function obj = mtimes(obj, right)
  if isa(obj, 'tseries')
    if isa(right, 'tseries')
      for k=obj.m_ord:-1:1
        coeffs = cellfun(@mtimes, obj.m_series(1:k), right.m_series(k:-1:1), 'UniformOutput', false);
        coeffsS = coeffs{1};
        for i=2:length(coeffs)
          coeffsS = coeffsS + coeffs{i};
        end
%        hdim = length(size(coeffs{1})) + 1;
%        coeffsT = cat(hdim, coeffs{:});
%        coeffsS = sum(coeffsT, hdim);
        obj.m_series{k} = coeffsS;
%        s = zeros(size(obj.m_series{k}));
%        for i=1:k
%          s = s + obj.m_series{i} * right.m_series{k-i+1}
%        end
%        obj.m_series{k} = s;
      end
    else
      for k=1:obj.m_ord
        obj.m_series{k} = obj.m_series{k} * right;
      end
    end
  else
    val = obj;
    obj = right;
    for k=1:obj.m_ord
      obj.m_series{k} = val * obj.m_series{k};
    end
  end
end
function obj = abs(obj)
  if isreal(obj.m_series{1})
    less0 = obj.m_series{1} < 0;
    eq0 = obj.m_series{1} == 0;
    if any(eq0(:))
      warning('adimat:tseries:abs:argZero', '%s', ...
              'abs is not defined at 0');
    end
    for i=1:obj.m_ord
      obj.m_series{i}(less0) = -obj.m_series{i}(less0);
    end
  else
    % complex case
    obj = sqrt(real(obj).^2 + imag(obj).^2);
  end
end
function display(obj)
  fprintf('Taylor series of order %d of size %s\n', obj.m_ord, mat2str(size(obj)));
%  for i=1:obj.m_ord
  for i=1:1
    fprintf('Coefficients of order %d:\n', i-1);
    disp(obj.m_series{i});
  end
end
function obj = rdivide(obj, right)
  if ~isa(obj, 'tseries')
    obj = tseries(obj);
  end
  if isa(right, 'tseries')
    obj.m_series{1} = obj.m_series{1} ./ right.m_series{1};
    for k=2:obj.m_ord
      for j=2:k
        obj.m_series{k} = obj.m_series{k} - obj.m_series{j-1} .* right.m_series{k-j+2} ;
      end
      obj.m_series{k} = obj.m_series{k} ./ right.m_series{1};
    end
  else
    for k=1:obj.m_ord
      obj.m_series{k} = obj.m_series{k} ./ right;
    end
  end
end
function obj = asech(obj)
  obj = log(1 ./ obj + sqrt(1 ./ obj.^2 + 1));
end
function obj = repmat(obj, varargin)
  obj.m_series = cellfun(@(x) repmat(x, varargin{:}), obj.m_series, 'UniformOutput', false);
end
function obj = min(obj, right)
  if nargin == 1
    [obj, mi] = min1(obj);
  elseif nargin == 2
    [obj] = min2(obj, right);
  end
end
function obj = transpose(obj)
  obj = unop(obj, @transpose);
end
% function [t, y_obj] = ode15i(func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode15i(func, ts, y0)
  [t, y_obj] = ode_generic(@ode15i, func, ts, y0);
function obj = roots(obj)
  assert(obj.maxorder = 1);
  [par, x] = partial_roots(obj.m_series{1});
  obj.m_series{1} = x;
  obj.m_series{2} = reshape(par * obj.m_series{2}(:), size(x));
function obj = sech(obj)
  [~, obj] = sinhcosh(obj);
  obj = 1 ./ obj;
end
function varargout = subsref(obj, ind)
%  fprintf('tseries.subsref: %s, nargout=%d\n', num2str(size(obj)),nargout);
  switch ind(1).type
   case '()'
    for k=1:obj.m_ord
      obj.m_series{k} = subsref(obj.m_series{k}, ind);
    end
    varargout{1} = obj;
   case '{}'
    if length(ind(1).subs) > 1
      error('adimat:tseries:subsref:multipleindexincurlybrace',...
            ['there are %d indices in the curly brace reference, but ' ...
             'only one is allowed'], length(ind(1).subs));
    end
    cinds = ind(1).subs{1};
    if isa(cinds, 'char') && isequal(cinds, ':')
      selected = obj.m_series(1:obj.m_ord);
    else
      selected = obj.m_series(cinds);
    end
    if length(ind) > 1
      if length(selected) > 1
        error('adimat:tseries:subsref:badcellreference',...
              '%s', 'Bad tseries coefficient reference operation');
      end
      [varargout{1:nargout}] = subsref(selected{1}, ind(2:end));
    else
      varargout = selected;
    end
   otherwise
    [varargout{1:nargout}] = subsref(struct(obj), ind);
  end
end
function [obj] = exp(obj)
  eT = obj.m_series;
  eT{1} = exp(obj.m_series{1});
  for j=1:obj.m_ord-1
    eT{j+1} = eT{1} .* obj.m_series{j+1};
    for i=1:j-1
      eT{j+1} = eT{j+1} + ((j-i)/j) .* eT{i+1} .* obj.m_series{j-i+1};
    end
  end
  obj.m_series = eT;
end
function obj = sinh(obj)
  [obj] = sinhcosh(obj);
end
function obj = acosh(obj)
  obj = log(obj + sqrt(obj + 1).*sqrt(obj - 1));
end
function [obj] = log10(obj)
  obj = log(obj) ./ log(10);
end
function res = ge(obj, v)
  res = cmpop(obj, v, @ge);
end
function [obj] = expm(obj)
  obj = adimat_expm(obj);
end
function obj = uminus(obj)
  obj = unop(obj, @uminus);
end
function obj = sec(obj)
  [~, obj] = sincos(obj);
  obj = 1 ./ obj;
end
function obj = unop(obj, handle)
  obj.m_series = cellfun(handle, obj.m_series, 'UniformOutput', false);
end
function res = le(obj, v)
  res = cmpop(obj, v, @le);
end
% function [t, y_obj] = ode_generic(integrator, func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode_generic(integrator, func, ts, y0)
  if y0.m_ord > 2
    error('adimat:tseries:det:unsupportedOrder', ...
          ['Taylor coefficients of the functions odeXYZ (ode23, ode15s, etc.) are only supported ' ...
           'up to first order, but the maximum order is set to %d'], ...
          obj.m_ord -1);
  end
  % get info about ODE function
  r = functions(func);
  % backup global ndd variable
  curndd = admGetNDD;
  % parse lambda function handle
  [token] = regexp(r.function, '@\((\w+),\W*(\w+)\)\W*(\w+)\W*\((\w+),\W*(\w+),\W*(\w+)\)', 'tokens');
  token = token{1};
  arg_t = token{4};
  arg_y = token{5};
  name_f = token{3};
  arg_p = token{6};
  % get the ode function handle
  fode = str2func(name_f);
  % get the parameter p
  if ~iscell(r.workspace)
    r.workspace = {r.workspace};
  end
  p = r.workspace{1}.(arg_p);
  p_double = p.m_series{1};
  y0_double = y0.m_series{1};
  % run once to get the ode function differentiated, preparing for
  % following runs with nochecks=1
  dfdydp = admDiffFor(fode, 1, ts, y0_double, p_double, admOptions('i', [2,3]));
  g_fode = str2func(['g_' name_f]);
  % construct augmented ODE system
  useDriver = false;
  aug_ode = mkaugode(g_fode, fode, ts, y0_double, p_double, useDriver);
  % initial value
  augy0 = [ y0_double(:); zeros(numel(y0) .* numel(p), 1); reshape(eye(numel(y0)),[],1) ];
  % when using manual invocation of differentiated code, set
  % derivative class to scalar mode
  if ~useDriver
    adimat_derivclass scalar_directderivs
  end
  % and run integrator
  [t, y] = integrator(@(t,y) aug_ode(t,y,p_double), ts, augy0);
  % reset global ndd variable, and derivative class, which was modified
  % by the admTaylorFor calls in aug_ode
  adimat_derivclass arrderivclass
  set(g_dummy, 'ndd', curndd);
  nt = numel(t);
  ny = numel(y0);
  np = numel(p);
  y_orig = y(:,1:ny);
  y_obj = tseries(y_orig);
  dydp  = reshape(y(:,ny+1:ny+ny*np),[nt.*ny, np]);
  dydy0 = reshape(y(:,ny+ny*np+1:end),[nt.*ny, ny]);
  dp = dydp * p.m_series{2}(:);
  dy0 = dydy0 * y0.m_series{2}(:);
  y_obj.m_series{2} = reshape(dp + dy0, size(y_orig));
end
function aug_ode = mkaugode(g_fode, fode, ts, y0, p, useDriver)
  fode_yp = mktaydiff_yp(g_fode, fode, ts, y0, p, useDriver);
  function [dy_new] = augode_(t_, y_, p_)
      ny = numel(y0);
      np = numel(p);
      y_orig = y_(1:ny);
      dydp = y_(ny+1:ny+np*ny);
      dydp = reshape(dydp,ny,np);
      dydy0 = y_(ny+np*ny+1:end);
      dydy0 = reshape(dydy0,ny,ny);
      dy = fode(t_, y_orig, p_);
      [dfdy, dfdp] = fode_yp(t_, y_orig, p_);
      ddydp = dfdy * dydp + dfdp;
      ddydy0 = dfdy * dydy0;
      dy_new = [ dy(:); ddydp(:); ddydy0(:) ];
  end
  aug_ode = @augode_;
end
function f_ode_py = mktaydiff_yp(g_fode, fode, ts, y0, p, useDriver)
  function [dfdy, dfdp] = f_ode_py_(t_, y_, p_)
    %    dfdyp = admTaylorFor(fode, 1, t_, y_, p_, admOptions('i', [2,3], 'nochecks', 1));
    %    dfdyp = admDiffFor(fode, 1, t_, y_, p_, admOptions('i', [2,3], 'nochecks', 1));
    ny = numel(y_);
    np = numel(p_);
    if useDriver
      [J, dy] = admDiffFor(fode, 1, t_, y_, p_, admOptions('i', [2,3], 'nochecks', 1));
      dfdy = dy(:,1:ny);
      dfdp = dy(:,ny+1:end);
    else
      dfdy = zeros(ny, ny);
      dfdp = zeros(ny, np);
      g_y = zeros(ny, 1);
      g_p = zeros(np, 1);
      for k=1:ny
        g_y(k) = 1;
        [g_dy, dy] = g_fode(t_, g_y, y_, g_p, p_);
        dfdy(:,k) = g_dy;
        g_y = zeros(ny, 1);
      end
      for k=1:np
        g_p(k) = 1;
        [g_dy, dy] = g_fode(t_, g_y, y_, g_p, p_);
        dfdp(:,k) = g_dy;
        g_p = zeros(np, 1);
      end
    end
  end
  f_ode_py = @f_ode_py_;
end
function obj = mrdivide(obj, right)
  obj = (right' \ obj')';
end
function obj = minus(obj, right)
  if isa(obj, 'tseries')
    if isa(right, 'tseries')
      obj.m_series = cellfun(@minus, obj.m_series, right.m_series, 'UniformOutput', false);
    else
      if isscalar(obj) && ~isscalar(right)
        obj = repmat(obj, size(right));
      end
      obj.m_series{1} = obj.m_series{1} - right;
    end
  else
    val = obj;
    obj = right;
    if isscalar(obj) && ~isscalar(val)
      obj = repmat(obj, size(val));
    end
    obj.m_series{1} = val - obj.m_series{1};
    obj.m_series(2:obj.m_ord) = cellfun(@uminus, obj.m_series(2:obj.m_ord), 'UniformOutput', false);
  end
end
function [obj P] = sort(obj, varargin)
  [obj.m_series{1} P] = sort(obj.m_series{1}, varargin{:});
  if nargin < 2 || ischar(varargin{1})
    dim = adimat_first_nonsingleton(obj.m_series{1});
  else
    dim = varargin{1};
  end
  gP = mk1dperm(P, dim);
  for k=2:obj.m_ord
    obj.m_series{k} = obj.m_series{k}(gP);
  end
end
% $Id: sort.m 4981 2015-05-11 08:26:05Z willkomm $
function [sobj, cobj] = sincos(obj)
  sT = obj.m_series;
  cT = obj.m_series;
  sT{1} = sin(obj.m_series{1});
  cT{1} = cos(obj.m_series{1});
  sT{2} = times(obj.m_series{2}, cT{1});
  cT{2} = -times(obj.m_series{2}, sT{1});
  for j=2:obj.m_ord-1
    sT{j+1} = times(obj.m_series{j+1}, cT{1});
    cT{j+1} = -times(obj.m_series{j+1}, sT{1});
    for i=1:j-1
      sT{j+1} = plus(sT{j+1}, times(times(cT{i+1}, obj.m_series{j-i+1}), (j-i)/j));
      cT{j+1} = minus(cT{j+1}, times(times(sT{i+1}, obj.m_series{j-i+1}), (j-i)/j));
    end
  end
  for j=1:obj.m_ord-1
    sT{j+1} = zeros(size(sT{j+1}));
    cT{j+1} = zeros(size(cT{j+1}));
    for i=0:j-1
      sT{j+1} = sT{j+1} + ((j-i)/j) .* cT{i+1} .* obj.m_series{j-i+1};
      cT{j+1} = cT{j+1} - ((j-i)/j) .* sT{i+1} .* obj.m_series{j-i+1};
    end
  end
  sobj = obj;
  cobj = obj;
  sobj.m_series = sT;
  cobj.m_series = cT;
end
function obj = horzcat(obj, varargin)
  obj = cat(2, obj, varargin{:});
end
function obj = mpower(obj, right)
  if isscalar(obj) && isscalar(right)
    obj = power(obj, right);
  else
    if isscalar(obj)
      obj = adimat_mpower(obj, right)
    else
      error('adimat:tseries:mpower:unsupportedArguments', '%s',...
            ['For mpower, the case matrix^scalar ' ...
             'are not yet supported by the tseries class.']);
    end
  end
end
function obj = sum(obj, varargin)
  obj = unopV(obj, @sum, varargin{:});
end
% function [t, y_obj] = ode23s(func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode23s(func, ts, y0)
  [t, y_obj] = ode_generic(@ode23s, func, ts, y0);
function obj = cos(obj)
  [~, obj] = sincos(obj);
end
function obj = acos(obj)
  obj = -i .* log( obj + i.*sqrt(1 - obj.^2) );
end
% function [t, y_obj] = ode23tb(func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode23tb(func, ts, y0)
  [t, y_obj] = ode_generic(@ode23tb, func, ts, y0);
function obj = linsolve(obj, right, opts)
  if isscalar(obj)
    obj = right ./ obj;
  else
    [m n] = size(obj);
    if nargin < 3
      opts = struct();
      if m ~= n
        opts.RECT = true;
      end
    end
    if m == n || (~admIsOctave() && m < n)
      obj = linsolve_square(obj, right, opts);
    elseif m > n && strcmp(admGetPref('nonSquareSystemSolve'), 'fast')
      objt = obj';
      obj = linsolve_square(objt * obj, objt * right, opts);
    else  
      obj = adimat_sol_qr(obj, right);
    end
  end
end
function res = sign(obj)
  [res] = sign(obj.m_series{1});
end
function obj = diag(obj)
  obj = unopc(obj, @diag);
end
function obj = atan2(y, x)
  obj = adimat_atan2(y, x);
end
function obj = acsch(obj)
  obj = log(1 ./ obj + sqrt(1 ./ obj + 1) .* sqrt(1 ./ obj - 1));
end
function [res] = ceil(obj)
  res = ceil(obj.m_series{1});
end
function res = cmpop(obj, right, handle)
  if isa(obj, 'tseries')
    if isa(right, 'tseries')
      res = handle(obj.m_series{1}, right.m_series{1});
    else
      res = handle(obj.m_series{1}, right);
    end
  else
    res = handle(obj, right.m_series{1});
  end
end
function obj = acoth(obj)
  obj = 0.5 .* log((obj + 1) ./ (obj - 1));
end
function obj = ldivide(obj, right)
  obj = right / obj;
end
% function [t, y_obj] = ode45(func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode45(func, ts, y0)
  [t, y_obj] = ode_generic(@ode45, func, ts, y0);
function [obj, mi] = min1(obj)
  [mv, mi] = min(obj.m_series{1});
  for i=1:obj.m_ord
    obj.m_series{i} = obj.m_series{i}(mi);
  end
end
function res = eq(obj, v)
  res = cmpop(obj, v, @eq);
end
function [obj] = min2(obj, right)
  if isscalar(obj)
    szr = size(right);
    obj = repmat(obj, szr);
  end
  if isa(obj, 'tseries')
    if isa(right, 'tseries')
      ll = obj.m_series{1} > right.m_series{1};
      for i=1:obj.m_ord
        obj.m_series{i}(ll) = right.m_series{i}(ll);
      end
    else
      ll = obj.m_series{1} > right;
      obj.m_series{1}(ll) = right;
      for i=2:obj.m_ord
        obj.m_series{i}(ll) = 0;
      end
    end
  else
    ll = obj > right.m_series{1};
    obj = tseries(obj);
    for i=1:obj.m_ord
      obj.m_series{i}(ll) = right.m_series{i}(ll);
    end
  end
end
function [obj] = log(obj)
  lT = obj.m_series;
  lT{1} = log(obj.m_series{1});
  eq0 = obj.m_series{1} == 0;
  if any(eq0(:))
    warning('adimat:tseries:log:argZero', '%s', 'log(x) not defined for x==0');
    lT{2}(~eq0) = lT{2}(~eq0) ./ obj.m_series{1}(~eq0);
    lT{2}(eq0) = 0;
  else
    lT{2} = lT{2} ./ obj.m_series{1};
  end
  for j=2:obj.m_ord-1
    jsum = j .* obj.m_series{j+1};
    for i=1:j-1
      jsum = jsum - i .* lT{i+1} .* obj.m_series{j-i+1};
    end
    lT{j+1} = jsum;
    lT{j+1}(~eq0) = lT{j+1}(~eq0) ./ (obj.m_series{1}(~eq0) .* j);
    lT{j+1}(eq0) = 0;
  end
  obj.m_series = lT;
end
function obj = triu(obj, varargin)
  obj = unopc(obj, @triu, varargin{:});
end
function res = linsolve_square(obj, right, opts)
  if isa(obj, 'tseries')
    if isa(right, 'tseries')
      sol = linsolve(obj.m_series{1}, right.m_series{1}, opts);
      res = tseries(sol);
      % res.m_series{2} = obj.m_series{1} \ (right.m_series{2} - obj.m_series{2}*res.m_series{1});
      %
      % res.m_series{3} = 0.5 .* (obj.m_series{1} \ (right.m_series{3}...
      %                                      - 2.*obj.m_series{2}*res.m_series{2}...
      %                                      - obj.m_series{3}*res.m_series{1}));
      %
      % res.m_series{3} = (obj.m_series{1} \ (right.m_series{3}...
      %                                      - obj.m_series{2}*res.m_series{2}...
      %                                      - obj.m_series{3}*res.m_series{1}));

      for k=2:obj.m_ord
        Z = obj.m_series{k} * res.m_series{1};
        if k > 2
          coeffs = cellfun(@mtimes, obj.m_series(2:k-1), res.m_series(k-1:-1:2), 'UniformOutput', false);
          coeffsS = coeffs{1};
          for i=2:length(coeffs)
            coeffsS = coeffsS + coeffs{i};
          end
          Z = Z + coeffsS;
        end
        res.m_series{k} = linsolve(obj.m_series{1}, right.m_series{k} - Z, opts);
      end
    else
      sol = linsolve(obj.m_series{1}, right, opts);
      res = tseries(sol);
      for k=2:obj.m_ord
        Z = obj.m_series{k} * res.m_series{1};
        if k > 2
          coeffs = cellfun(@mtimes, obj.m_series(2:k-1), res.m_series(k-1:-1:2), 'UniformOutput', false);
          coeffsS = coeffs{1};
          for i=2:length(coeffs)
            coeffsS = coeffsS + coeffs{i};
          end
          Z = Z + coeffsS;
        end
        res.m_series{k} = linsolve(obj.m_series{1}, -Z, opts);
      end
    end
  else
    sol = obj \ right.m_series{1};
    res = tseries(sol);
    for k=2:res.m_ord
      res.m_series{k} = linsolve(obj, right.m_series{k}, opts);
    end
  end
end
function z = eval(obj, h, maxorder)
  if nargin < 3
    maxorder = obj.m_ord-1;
  end
  z = obj.m_series{1} + deval(obj, h, maxorder);
function obj = cot(obj)
  [s, c] = sincos(obj);
  obj = c ./ s;
end
function obj = plus(obj, right)
  if isa(obj, 'tseries')
    if isa(right, 'tseries')
      obj.m_series = cellfun(@plus, obj.m_series, right.m_series, 'UniformOutput', false);
    else
      if isscalar(obj) && ~isscalar(right)
        obj = repmat(obj, size(right));
      end
      obj.m_series{1} = obj.m_series{1} + right;
    end
  else
    val = obj;
    obj = right;
    if isscalar(obj) && ~isscalar(val)
      obj = repmat(obj, size(val));
    end
    obj.m_series{1} = val + obj.m_series{1};
  end
end
function [varargout] = eigs(a, varargin)
  assert(a.m_ord == 2, 'The eig methods supports first order derivatives only');
  if nargout == 1
    [g_l, l] = g_eigs(a.m_series{2}, a.m_series{1}, varargin{:});
    l = tseries(l);
    l.m_series{2} = g_l;
    varargout = {l};
  elseif nargout == 2
    [g_V, V, g_D, D] = g_eigs2(a.m_series{2}, a.m_series{1}, varargin{:});
    tV = tseries(V);
    tD = tseries(D);
    tV.m_series{2} = g_V;
    tD.m_series{2} = g_D;
    varargout = {tV tD};
  end
end
% $Id: eigs.m 5016 2015-05-19 21:33:29Z willkomm $
% function [t, y_obj] = ode113(func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode113(func, ts, y0)
  [t, y_obj] = ode_generic(@ode113, func, ts, y0);
function obj = tril(obj, varargin)
  obj = unopc(obj, @tril, varargin{:});
end
function varargout = svd(obj)
  [varargout{1:nargout}] = adimat_svd(obj);
end
function res = isreal(obj)
  res = isreal(obj.m_series{1});
end
function [obj] = log2(obj)
  obj = log(obj) ./ log(2);
end
function [obj] = trapz(varargin)
  obj = adimat_trapz(varargin{:});
end
function obj = zerobj(obj)
  zv = zeros(size(obj.m_series{1}));
  obj.m_series(1:obj.m_ord) = {zv};
end
% function [t, y_obj] = ode23(func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode23(func, ts, y0)
  [t, y_obj] = ode_generic(@ode23, func, ts, y0);
function obj = coth(obj)
  [sh, ch] = sinhcosh(obj);
  obj = ch ./ sh;
end
function obj = cosh(obj)
  [~, obj] = sinhcosh(obj);
end
function obj = mldivide(obj, right)
  if isscalar(obj)
    obj = right ./ obj;
  else
    [m n] = size(obj);
    if m == n || (~admIsOctave() && m < n)
      obj = mldivide_square(obj, right);
    elseif m > n && strcmp(admGetPref('nonSquareSystemSolve'), 'fast')
      objt = obj';
      obj = mldivide_square(objt * obj, objt * right);
    else  
      obj = adimat_sol_qr(obj, right);
    end
  end
end
function obj = asec(obj)
  obj = acos(1 ./ obj);
end
function val = value(obj)
  val = obj.m_series{1};
end
function obj = real(obj)
  obj = unop(obj, @real);
end
function obj = calln(handle, varargin)
  obj = varargin{1};
  nparm = nargin-1;
  tmpc = cell(nparm, 1);
  for k=1:nargin-1
    tmpc{k} = varargin{k}.m_series{1};
  end
  obj.m_series{1} = handle(tmpc{:});
  for i=2:obj.m_ord
    tmpc = cell(nparm, 1);
    for k=1:nargin-1
      tmpc{k} = varargin{k}.m_series{i};
    end
    obj.m_series{i} = calln(handle, tmpc{:});
  end
end
function obj = asinh(obj)
  obj = log(obj + sqrt(obj.^2 + 1));
end
function l = length(obj)
  l = max(size(obj));
end
function obj = permute(obj, order)
  obj = unopV(obj, @permute, order);
end
% function [t, y_obj] = ode15s(func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode15s(func, ts, y0)
  [t, y_obj] = ode_generic(@ode15s, func, ts, y0);
function obj = bsxfun(handle, obj, right)
  obj = adimat_bsxfun(handle, obj, right);
end
end
end
