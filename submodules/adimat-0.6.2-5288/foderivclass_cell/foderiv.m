classdef foderiv

properties
  m_derivs
  m_ndd
end

methods(Static)
function r = option(name, val)
  persistent global_ndd global_inner
  if nargin < 2
    r = sprintf('unknown field %s', name);
    switch name
     case {'ndd', 'NumberOfDirectionalDerivatives'}
      r = global_ndd;
     case {'inner'}
      if isempty(global_inner)
        global_inner = @double;
      end
      r = global_inner;
     case {'DerivativeClassVersion'}
      r = 0.7;
     case {'DerivativeClassName'}
      r = 'foderiv';
     case {'DerivativeClassKind'}
      r = 'foderiv';
    end
  else
    switch name
     case {'ndd', 'NumberOfDirectionalDerivatives'}
      global_ndd = val;
    end
  end
end
end

methods

function obj = foderiv(val,ndd)
  if isstruct(val)
    obj.m_ndd = val.m_ndd;
    obj.m_derivs = val.m_derivs;
  else
    if nargin < 2
      ndd = foderiv.option('ndd');
    end
    obj.m_ndd = ndd;
    obj.m_derivs = cell(ndd, 1);
    obj = obj.init(val);
  end
end

function obj = init(obj, val)
%  inner = tseries.option('inner');
  obj.m_derivs = cellfun(@(x) val, obj.m_derivs, 'UniformOutput', false);
end

function obj = zero(obj, val)
  obj = obj.init(zeros(size(val)));
end

function obj = zerobj(obj)
  sz = obj.size();
  obj = obj.init(zeros(sz));
end

function obj = set(obj, name, val)
  switch name
   otherwise
    foderiv.option(name, val);
  end
end

function val = get(obj, name)
  switch name
   otherwise
    val = foderiv.option(name);
  end
end

function val = admGetDD(obj, i)
  val = obj.m_derivs{i};
end

function val = toDouble(obj)
  if isobject(obj.m_derivs{1})
    nsz = [1 size(toDouble(obj.m_derivs{1}))];
    vals = cellfun(@(x) reshape(toDouble(x), nsz), obj.m_derivs, 'UniformOutput', false);
  else
    nsz = [1 size(obj.m_derivs{1})];
    vals = cellfun(@(x) reshape(x, nsz), obj.m_derivs, 'UniformOutput', false);
  end
  val = cat(1, vals{:});
end

function [varargout] = size(obj, varargin)
  [varargout{1:nargout}] = size(obj.m_derivs{1}, varargin{:});
end

function res = numel(obj, varargin)
%  fprintf('foderiv.numel: %s\n', num2str(size(obj)));
%  disp(varargin);
  if nargin < 2
    res = 1;
    return
  end
  if (ischar(varargin{1}) & (varargin{1}==':'))
    res = obj.m_ndd(1);
  else
    res = length(varargin{1});
  end
%  fprintf('foderiv.numel: %d\n', res);
end

function res = end(obj, k, n)
  sz = size(obj.m_derivs{1});
  if k < n
    res = sz(k);
  else
    res = prod(sz(k:end));
  end
end

function disp(obj)
  fprintf('N-Times wrapper with %d directions of size %s\n', obj.m_ndd, ...
          mat2str(size(obj)));
  for i=1:obj.m_ndd
    fprintf('Direction %d:\n', i);
    disp(obj.m_derivs{i});
  end
end

function obj = cat(dim, obj, varargin)
  d_cells = cellfun(@(x) x.m_derivs, varargin, 'UniformOutput', false);
  obj.m_derivs = cellfun(@(varargin) cat(dim, varargin{:}), obj.m_derivs, ...
                         d_cells{:}, 'UniformOutput', false);
end

function obj = horzcat(obj, varargin)
  d_cells = cellfun(@(x) x.m_derivs, varargin, 'UniformOutput', false);
  obj.m_derivs = cellfun(@(varargin) horzcat(varargin{:}), obj.m_derivs, ...
                         d_cells{:}, 'UniformOutput', false);
end

function obj = vertcat(obj, varargin)
  d_cells = cellfun(@(x) x.m_derivs, varargin, 'UniformOutput', false);
  obj.m_derivs = cellfun(@(varargin) vertcat(varargin{:}), obj.m_derivs, ...
                         d_cells{:}, 'UniformOutput', false);
end

function obj = reshape(obj, varargin)
  obj.m_derivs = cellfun(@(x) reshape(x, varargin{:}), obj.m_derivs, ...
                         'UniformOutput', false);
end

function varargout = subsref(obj, ind)
%  fprintf('foderiv.subsref: %s, nargout=%d\n', num2str(size(obj)),nargout);
%  disp(ind);
  switch ind(1).type
   case '()'
    obj.m_derivs = cellfun(@(x) subsref(x, ind), obj.m_derivs, 'UniformOutput', false);
    varargout{1} = obj;
   case '{}'
    if length(ind(1).subs) > 1
      error('adimat:foderiv:subsref:multipleindexincurlybrace',...
            ['there are %d indices in the curly brace reference, but ' ...
             'only one is allowed'], length(ind(1).subs));,
    end
    cinds = ind(1).subs{1};
    if (isa(cinds, 'char') & (cinds==':'))
      selected = {obj.m_derivs{1:obj.m_ndd}};
    else
      selected = {obj.m_derivs{cinds}};
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

function obj = subsasgn(obj, ind, rhs)
  switch ind(1).type
   case '()'
    if isa(rhs, 'foderiv')
      if isempty(obj) && isa(obj, 'double')
        obj = foderiv([]);
      end
      obj.m_derivs = cellfun(@(x, y) subsasgn(x, ind, y), obj.m_derivs, rhs.m_derivs, 'UniformOutput', false);
    else
      obj.m_derivs = cellfun(@(x) subsasgn(x, ind, rhs), obj.m_derivs, 'UniformOutput', false);
    end
    varargout{1} = obj;
   case '{}'
    ind1 = ind(1).subs;
%    if isa(rhs, 'foderiv')
%      obj.m_derivs(ind1{:}) = cellfun(@(x, y) subsasgn(x, ind(2:end), y), obj.m_derivs(ind1{:}), rhs.m_derivs, 'UniformOutput', false);
%    else
      if length(ind) > 1
        obj.m_derivs(ind1{:}) = cellfun(@(x) subsasgn(x, ind(2:end), rhs), obj.m_derivs(ind1{:}), 'UniformOutput', false);
      else
        csz = size(obj);
        rsz = size(rhs);
        if ~isequal(csz, rsz)
          error('adimat:foderiv:subsasgn:sizeMismatch', ...
                ['when setting a n-times direction, the size must ' ...
                 'be the same as the current size (%s), but it is %s'], ...
                mat2str(csz), mat2str(rsz));
        end
%        inner = tseries.option('inner');
%        rhsv = inner(rhs);
        obj.m_derivs{ind1{:}} = rhs;
      end
%    end
  end
end


function obj = unop(obj, handle)
  obj.m_derivs = cellfun(handle, obj.m_derivs, 'UniformOutput', false);
end

function obj = unopP(obj, handle, varargin)
  obj.m_derivs = cellfun(@(x) handle(x, varargin{:}), obj.m_derivs, 'UniformOutput', false);
end

function obj = unopWO(handle, wo, varargin)
  obj = varargin{wo};
  obj.m_derivs = cellfun(@(x) handle(varargin{1:wo-1}, x, varargin{wo+1:end}), ...
                         obj.m_derivs, 'UniformOutput', false);
end

function obj = binop(obj, right, handle, varargin)
  if isa(obj, 'foderiv')
    if isa(right, 'foderiv')
      if nargin == 3
        obj.m_derivs = cellfun(handle, obj.m_derivs, right.m_derivs, ...
                               'UniformOutput', false);
      elseif nargin == 4
        obj.m_derivs = cellfun(handle, obj.m_derivs, right.m_derivs, ...
                               repmat({ varargin{1:end} }, size(obj.m_derivs)), ...
                               'UniformOutput', false);
      else
        error(['when both args are objects there may be at most one ' ...
               'additional argument']);
      end
    else
      obj.m_derivs = cellfun(@(x) handle(x, right, varargin{:}), obj.m_derivs, 'UniformOutput', false);
    end
  else
    val = obj;
    obj = right;
    obj.m_derivs = cellfun(@(y) handle(val, y, varargin{:}), right.m_derivs, 'UniformOutput', false);
  end
end


function obj = plus(obj, right)
  obj = binop(obj, right, @plus);
end
function obj = plusdd(obj, right)
  obj = binop(obj, right, @plus);
end
function obj = plusddes(obj, right)
  obj = binop(obj, right, @plus);
end
function obj = plusdv(obj, right)
  obj = binop(obj, right, @plus);
end

function obj = minus(obj, right)
  obj = binop(obj, right, @minus);
end
function obj = minusdd(obj, right)
  obj = binop(obj, right, @minus);
end
function obj = minusddes(obj, right)
  obj = binop(obj, right, @minus);
end
function obj = minusdv(obj, right)
  obj = binop(obj, right, @minus);
end

function obj = fftimes(obj, right)
  if isa(obj, 'foderiv')
    for i=1:obj.m_ndd
      obj.m_derivs{i} = obj.m_derivs{i} .* right;
    end
  else
    val = obj;
    obj = right;
    for i=1:obj.m_ndd
      obj.m_derivs{i} = val .* obj.m_derivs{i};
    end
  end
end

function obj = times(obj, right)
  obj = binop(obj, right, @times);
end
function obj = timesdd(obj, right)
  obj = binop(obj, right, @times);
end
function obj = timesddes(obj, right)
  obj = binop(obj, right, @times);
end
function obj = timesdv(obj, right)
  obj = binop(obj, right, @times);
end
function obj = mtimes(obj, right)
  obj = binop(obj, right, @mtimes);
end

function obj = rdivide(obj, right)
  obj = binop(obj, right, @rdivide);
end
function obj = rdividedv(obj, right)
  obj = binop(obj, right, @rdivide);
end
function obj = mrdivide(obj, right)
  obj = binop(obj, right, @mrdivide);
end

function obj = ldivide(obj, right)
  obj = binop(obj, right, @ldivide);
end
function obj = mldivide(obj, right)
  obj = binop(obj, right, @mldivide);
end

function obj = linsolve(obj, right, varargin)
  obj = binop(obj, right, @linsolve, varargin{:});
end

function obj = transpose(obj)
  obj = unop(obj, @transpose);
end
function obj = ctranspose(obj)
  obj = unop(obj, @ctranspose);
end
function obj = uplus(obj)
  obj = unop(obj, @uplus);
end
function obj = uminus(obj)
  obj = unop(obj, @uminus);
end

function obj = sin(obj)
  obj = unop(obj, @sin);
end
function obj = cos(obj)
  obj = unop(obj, @cos);
end
function obj = tan(obj)
  obj = unop(obj, @tan);
end

function obj = exp(obj)
  obj = unop(obj, @exp);
end
function obj = log(obj)
  obj = unop(obj, @log);
end
function obj = sqrt(obj)
  obj = unop(obj, @sqrt);
end

function obj = real(obj)
  obj = unop(obj, @real);
end
function obj = imag(obj)
  obj = unop(obj, @imag);
end
function obj = conj(obj)
  obj = unop(obj, @conj);
end

function res = isreal(obj)
  res = isreal(obj.m_derivs{1});
end

function obj = call(handle, obj, varargin)
  obj = unopP(obj, handle, varargin{:});
end

function obj = callwo(handle, varargin)
  wo = find(cellfun(@isobject, varargin));
  obj = unopWO(handle, wo, varargin{:});
end

function obj = calln(handle, varargin)
  obj = varargin{1};
  nparm = nargin-1;
  for i=1:obj.m_ndd
    tmpc = cell(nparm, 1);
    for k=1:nargin-1
      tmpc{k} = varargin{k}.m_derivs{i};
    end
    obj.m_derivs{i} = handle(tmpc{:});
  end
end

function obj = sum(obj, varargin)
  obj = unopP(obj, @sum, varargin{:});
end

function res = cmpop(obj, right, handle)
  if isa(obj, 'foderiv')
    if isa(right, 'foderiv')
      res = handle(obj.m_derivs{1}, right.m_derivs{1});
    else
      res = handle(obj.m_derivs{1}, right);
    end
  else
    res = handle(obj, right.m_derivs{1});
  end
end

function res = lt(obj, v)
  res = cmpop(obj, v, @lt);
end
function res = le(obj, v)
  res = cmpop(obj, v, @le);
end
function res = gt(obj, v)
  res = cmpop(obj, v, @gt);
end
function res = ge(obj, v)
  res = cmpop(obj, v, @ge);
end
function res = eq(obj, v)
  res = cmpop(obj, v, @eq);
end
function res = ne(obj, v)
  res = cmpop(obj, v, @ne);
end

function [obj, mi] = max(obj)
  [mv, mi] = max(obj.m_derivs{1});
  for i=1:obj.m_ndd
    obj.m_derivs{i} = obj.m_derivs{i}(mi);
  end
end
function [obj, mi] = min(obj)
  [mv, mi] = min(obj.m_derivs{1});
  for i=1:obj.m_ndd
    obj.m_derivs{i} = obj.m_derivs{i}(mi);
  end
end
function res = sign(obj)
  [res] = sign(obj.m_derivs{1});
end

function res = toStruct(obj)
  res.m_derivs = obj.m_derivs;
  res.m_ndd = obj.m_ndd;
  res.className = 'foderiv';
end

end

end
