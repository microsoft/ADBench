classdef arrdercontdef

properties
  m_derivs
  m_ndd
  m_size
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
      r = 0.83;
     case {'DerivativeClassName'}
      r = 'arrdercontdef';
     case {'DerivativeClassKind'}
      r = 'array';
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

function obj = arrdercontdef(val, ndd, method)
  if nargin < 1
    val = 0;
  end
  if isstruct(val)
    obj.m_ndd = val.m_ndd;
    obj.m_size = val.m_size;
    obj.m_derivs = val.m_derivs;
  elseif isa(val, 'arrdercontdef')
    obj.m_ndd = val.m_ndd;
    obj.m_size = val.m_size;
    obj.m_derivs = [];
  else
    if nargin < 3
      if nargin < 2
        ndd = arrdercontdef.option('ndd');
      end
      obj.m_ndd = ndd;
      obj.m_size = size(val);
      obj.m_derivs = zeros([obj.m_ndd size(val)]);
      if ~isempty(val)
        obj.m_derivs(1,:) = val(:);
      end
    else
      % emulate adderiv behaviour... basically only for unit tests
      % to work
      tval = ndd;
      tndd = val;
      val = tval;
      ndd = tndd;
      if isempty(ndd)
        ndd = arrdercontdef.option('ndd');
      end
      obj.m_ndd = ndd;
      obj.m_size = size(val);
      obj.m_derivs = zeros([obj.m_ndd size(val)]);
    end
  end
end

function obj = set(obj, name, varargin)
  if isa(name, 'char')
    val = varargin{1};
    switch name
     case 'direct'
      obj.m_derivs = reshape(val, obj.m_ndd, []);
     case 'deriv'
      obj.m_derivs = val;
     otherwise
      arrdercontdef.option(name, val);
    end
  elseif isa(name, 'cell')
    inds = name{1};
    for i=1:length(inds)
      k = inds(i);
      val = varargin{i};
      if ~isequal(size(val), size(obj))
        error('adimat:arrdercontdef:set:dirder:wrongSize', 'The size of directional derivatives matrix to set is incompatible to number of elements expected. Expected: %s, supplied: %s.', ...
              mat2str(size(obj)), mat2str(size(val)));
      end
      obj.m_derivs(k, :) = val(:);
    end
  end
end

function val = get(obj, name)
  switch name
   case 'direct'
    dirs = cell(obj.m_ndd, 1);
    for i=1:obj.m_ndd
      dirs{i} = admGetDD(obj, i);
    end
    val = [dirs{:}];
   case 'deriv'
    val = obj.m_derivs;
   case 'size'
    val = size(obj);
   otherwise
    val = arrdercontdef.option(name);
  end
end

% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function val = admGetDD(obj, i)
  val = reshape(obj.m_derivs(i,:), obj.m_size);
end
% $Id: admGetDD.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = admSetDD(obj, i, val)
  obj.m_derivs(i,:) = val(:);
end
% $Id: admSetDD.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlat(obj, right, handle)
  if isobject(obj)
    isc_obj = prod(obj.m_size) == 1;
    dd1 = obj.m_derivs;
    if isobject(right)
      dd2 = right.m_derivs;
      if isc_obj
        obj.m_size = right.m_size;
      end
    else
      if isscalar(right)
        dd2 = right;
      else
        dd2 = reshape(full(right), [1 size(right)]);
        if isc_obj
          obj.m_size = size(right);
        end
      end
    end
  else
    dd2 = right.m_derivs;
    if isscalar(obj)
      dd1 = obj;
    else
      dd1 = reshape(full(obj), [1 size(obj)]);
      isc_right = prod(right.m_size) == 1;
      if isc_right
        right.m_size = size(obj);
      end
    end
    obj = right;
  end
  obj.m_derivs = bsxfun(handle, dd1, dd2);
end
% $Id: binopFlat.m 4357 2014-05-28 11:11:16Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlatdd(obj, right, handle)
  dd1 = obj.m_derivs;
  dd2 = right.m_derivs;
  if prod(obj.m_size) == 1
    obj.m_size = right.m_size;
  end
  obj.m_derivs = bsxfun(handle, dd1, dd2);
end
% $Id: binopFlatdd.m 4392 2014-06-03 07:41:31Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlatddes(obj, right, handle)
  obj.m_derivs = handle(obj.m_derivs, right.m_derivs);
end
% $Id: binopFlatddes.m 4497 2014-06-13 12:00:25Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlatdv(obj, right, handle)
%  fprintf(1, 'binopFlatdv: @%s, (%s), (%s)\n', func2str(handle), num2str(size(obj)), num2str(size(right)));
  dd1 = obj.m_derivs;
  if isscalar(right)
    obj.m_derivs = handle(obj.m_derivs, right);
  else
    dd2 = reshape(full(right), [1 size(right)]);
    if prod(obj.m_size) == 1
      obj.m_size = size(right);
    end
    obj.m_derivs = bsxfun(handle, dd1, dd2);
  end
%  fprintf(1, 'bsxfun: @%s, (%s), (%s)\n', func2str(handle), num2str(size(dd1)), num2str(size(dd2)));
end
% $Id: binopFlatdv.m 4585 2014-06-22 08:06:21Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function res = binopLoop(obj, right, handle)
  if isa(obj, 'arrdercontdef')
    if isa(right, 'arrdercontdef')
      if obj.m_ndd > 0
        dd1 = reshape(obj.m_derivs(1,:), obj.m_size);
        dd2 = reshape(right.m_derivs(1,:), right.m_size);
        dd = handle(dd1, dd2);
        res = arrdercontdef(dd);
        res.m_derivs(1,:) = dd(:);
        for i=2:obj.m_ndd
          dd1 = reshape(obj.m_derivs(i,:), obj.m_size);
          dd2 = reshape(right.m_derivs(i,:), right.m_size);
          dd = handle(dd1, dd2);
          res.m_derivs(i,:) = dd(:);
        end
      else
        dd1 = zeros(obj.m_size);
        dd2 = zeros(right.m_size);
        res = arrdercontdef(handle(dd1, dd2));
      end
    else
      if obj.m_ndd > 0
        dd1 = reshape(obj.m_derivs(1,:), obj.m_size);
        dd = handle(dd1, right);
        res = arrdercontdef(dd);
        res.m_derivs(1,:) = dd(:);
        for i=2:obj.m_ndd
          dd1 = reshape(obj.m_derivs(i,:), obj.m_size);
          dd = handle(dd1, right);
          res.m_derivs(i,:) = dd(:);
        end
      else
        dd1 = zeros(obj.m_size);
        dd2 = right;
        res = arrdercontdef(handle(dd1, dd2));
      end
    end
  else
    if right.m_ndd > 0
      val = obj;
      obj = right;
      dd2 = reshape(right.m_derivs(1,:), right.m_size);
      dd = handle(val, dd2);
      res = arrdercontdef(dd);
      res.m_derivs(1,:) = dd(:);
      for i=2:obj.m_ndd
        dd2 = reshape(right.m_derivs(i,:), right.m_size);
        dd = handle(val, dd2);
        res.m_derivs(i,:) = dd(:);
      end
    else
      dd1 = obj;
      dd2 = zeros(right.m_size);
      res = arrdercontdef(handle(dd1, dd2));
    end
  end
end
% $Id: binopLoop.m 4554 2014-06-15 12:18:54Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = call(handle, obj, varargin)
  if ismember(func2str(handle), methods(obj))
    obj = handle(obj, varargin{:});
  else
    obj = unopLoop(obj, handle, varargin{:});
    obj.m_derivs = full(obj.m_derivs);
  end
end
% $Id: call.m 4511 2014-06-13 13:57:43Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function varargout = callm(handle, varargin)

  nin= nargin-1;
  inp= cell(nin, 1);
  outp= cell(nargout, 1);

  obj = varargin{1};
  
  for i=1:obj.m_ndd
    for k=1:nin
      inp{k} = admGetDD(varargin{k}, i);
    end

    [outp{:}] = handle(inp{:});
    
    if i == 1
      for k=1:nargout
        varargout{k} = arrdercontdef(outp{k});
        varargout{k} = admSetDD(varargout{k}, i, outp{k});
      end
    else
      for k=1:nargout
        varargout{k} = admSetDD(varargout{k}, i, outp{k});
      end
    end

  end
end
% $Id: callm.m 4533 2014-06-14 20:57:59Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = calln(handle, varargin)
  if ismember(func2str(handle), methods(varargin{1}))
    obj = handle(varargin{:});
  else
    nparm = nargin-1;
    tmpc = cell(nparm, 1);
    obj = arrdercontdef(varargin{1});
    % first iteration, unrolled
    for k=1:nparm
      tmpc{k} = admGetDD(varargin{k}, 1);
    end
    dd = handle(tmpc{:});
    obj.m_size = size(dd);
    obj.m_derivs = zeros([obj.m_ndd, obj.m_size]);
    obj.m_derivs(1,:) = dd(:);
    for i=1:obj.m_ndd
      for k=1:nparm
        tmpc{k} = admGetDD(varargin{k}, i);
      end
      dd = handle(tmpc{:});
      obj.m_derivs(i,:) = dd(:);
    end
    obj.m_size = size(dd);
    obj.m_derivs = reshape(obj.m_derivs, [obj.m_ndd obj.m_size]);
  end
end
% $Id: calln.m 4507 2014-06-13 13:47:38Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = callwo(handle, varargin)
  wo = find(cellfun(@isobject, varargin));
  cobj = varargin{wo};
  if ismember(func2str(handle), methods(cobj))
    obj = handle(varargin{:});
  else
    obj = unopLoopWO(handle, wo, varargin{:});
    obj.m_derivs = full(obj.m_derivs);
  end
end
% $Id: callwo.m 4796 2014-10-08 10:37:06Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = cat(dim, varargin)
  areempty = cellfun(@isempty, varargin);
  nempty = varargin(~areempty);
  if isempty(nempty)
    obj = arrdercontdef([]);
  else
    dds = cellfun(@(x) full(x.m_derivs), nempty, 'UniformOutput', false);
    obj = arrdercontdef(nempty{1});
    obj.m_derivs = cat(dim + 1, dds{:});
    obj.m_size = computeSize(obj);
  end
end
% $Id: cat.m 4881 2015-02-15 21:01:00Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = cmpop(obj, right, handle)
  if isa(obj, 'arrdercontdef')
    if isa(right, 'arrdercontdef')
      res = handle(admGetDD(obj, 1), admGetDD(right, 1));
    else
      res = handle(admGetDD(obj, 1), right);
    end
  else
    res = handle(obj, admGetDD(right, 1));
  end
end
% $Id: cmpop.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = complex(a, b)
  obj = arrdercontdef(a);
  if isscalar(a)
    obj.m_size = size(b);
  end
  obj.m_derivs = complex(a.m_derivs, b.m_derivs);
end
% $Id: complex.m 4323 2014-05-23 09:17:16Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function [sz] = computeSize(obj)
  szd = size(obj.m_derivs);
  sz = szd(2:end);
  if length(sz) < 2
    if sz(1) == 0
      sz = [sz 0];
    else
      sz = [sz 1];
    end
  end
end
% $Id: computeSize.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = conj(obj)
  obj = unopFlat(obj, @conj);
end
% $Id: conj.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = cos(obj)
  obj = unopFlat(obj, @cos);
end
% $Id: cos.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = ctranspose(obj)
  obj.m_derivs = permute(obj.m_derivs, [1 3 2]);
  if ~isreal(obj.m_derivs)
    obj.m_derivs = conj(obj.m_derivs);
  end
  obj.m_size = fliplr(obj.m_size);
end
% $Id: ctranspose.m 4329 2014-05-23 15:32:43Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = cumsum(obj, k)
  if nargin < 2
    k = adimat_first_nonsingleton(obj);
  end
  obj.m_derivs = cumsum(obj.m_derivs, k+1);
  obj.m_size = computeSize(obj);
end
% $Id: cumsum.m 4323 2014-05-23 09:17:16Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = diff(obj, n, k)
  if nargin < 2
    n = 1;
  end
  if nargin < 3
    k = adimat_first_nonsingleton(obj);
  end
  obj.m_derivs = diff(obj.m_derivs, n, k+1);
  obj.m_size = computeSize(obj);
end
% $Id: diff.m 4323 2014-05-23 09:17:16Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function disp(obj)
  fprintf('N-Times wrapper with %d directions of size %s\n', obj.m_ndd, ...
          mat2str(size(obj)));
  for i=1:obj.m_ndd
    fprintf('Direction %d:\n', i);
    disp(admGetDD(obj, i));
  end
end
% $Id: disp.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = end(obj, k, n)
  if k < n
    res = obj.m_size(k);
  else
    res = prod(obj.m_size(k:end));
  end
end
% $Id: end.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = eq(obj, v)
  res = cmpop(obj, v, @eq);
end
% $Id: eq.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = exp(obj)
  obj = unopFlat(obj, @exp);
end
% $Id: exp.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = fft(obj, n, k)
  if nargin < 2
    n = [];
  end
  if nargin < 3
    k = adimat_first_nonsingleton(obj);
  end
  if admIsOctave() && k+1 > length(size(obj.m_derivs))
    % note: this concerns only trailing dimensions > 2 which are
    % singleton. hence repmat to n works
    obj.m_derivs = repmat(obj.m_derivs, adimat_repind(length(size(obj.m_derivs)), k+1,n));
    obj.m_size(k) = n;
  else
    obj.m_derivs = fft(obj.m_derivs, n, k+1);
    obj.m_size = computeSize(obj);
  end
end
% $Id: fft.m 4829 2014-10-13 07:06:33Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = flipdim(obj, k)
  obj.m_derivs = flipdim(obj.m_derivs, k+1);
end
% $Id: flipdim.m 4323 2014-05-23 09:17:16Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = fliplr(obj)
  obj = flipdim(obj, 2);
end
% $Id: fliplr.m 4323 2014-05-23 09:17:16Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = flipud(obj)
  obj = flipdim(obj, 1);
end
% $Id: flipud.m 4323 2014-05-23 09:17:16Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = full(obj)
end
% $Id: full.m 4323 2014-05-23 09:17:16Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = ge(obj, v)
  res = cmpop(obj, v, @ge);
end
% $Id: ge.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = gt(obj, v)
  res = cmpop(obj, v, @gt);
end
% $Id: gt.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = horzcat(obj, varargin)
  obj = cat(2, obj, varargin{:});
end
% $Id: horzcat.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = ifft(obj, varargin)
  mode = 'nonsymmetric';
  if nargin > 1 && ischar(varargin{end})
    mode = varargin{end};
    varargin = varargin(1:end-1);
  end
  if length(varargin) < 1
    n = [];
  else
    n = varargin{1};
  end
  if length(varargin) < 2
    k = adimat_first_nonsingleton(obj);
  else
    k = varargin{2};
  end
  if admIsOctave()
    modeArgs = {};
  else
    modeArgs = {mode};
  end
  if admIsOctave() && k+1 > length(size(obj.m_derivs))
    % note: this concerns only trailing dimensions > 2 which are
    % singleton. hence repmat to n works
    obj.m_derivs = repmat(obj.m_derivs, adimat_repind(length(size(obj.m_derivs)), k+1,n))./n;
    obj.m_size(k) = n;
  else
    obj.m_derivs = ifft(obj.m_derivs, n, k+1, modeArgs{:});
    obj.m_size = computeSize(obj);
  end
end
% $Id: ifft.m 4829 2014-10-13 07:06:33Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = imag(obj)
  obj = unopFlat(obj, @imag);
end
% $Id: imag.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = ipermute(obj, order)
  obj.m_derivs = ipermute(obj.m_derivs, [1 order+1]);
  obj.m_size(order) = obj.m_size;
end
% $Id: ipermute.m 4323 2014-05-23 09:17:16Z willkomm $
function r = isempty(obj)
  r = prod(obj.m_size) == 0;
end
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = isreal(obj)
  res = isreal(admGetDD(obj, 1));
end
% $Id: isreal.m 3862 2013-09-19 10:50:56Z willkomm $
function r = isscalar(obj)
  r = prod(obj.m_size) == 1;
end
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = ldivide(obj, right)
  obj = binopFlat(obj, right, @ldivide);
end
% $Id: ldivide.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = le(obj, v)
  res = cmpop(obj, v, @le);
end
% $Id: le.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function res = linsolve(obj, right, varargin)
  if isobject(obj)
    warning('why here? This probably shows a bug');
    obj = binopLoop(obj, right, @linsolve);
  else
    [m n] = size(obj);
    if nargin > 2
      opts = varargin{1};
    else
      opts = struct();
      if m ~= n
        opts.RECT = true;
      end
    end
    if isscalar(obj)
      res = ldivide(obj, right);
    else
      if isfield(opts, 'TRANSA') && opts.TRANSA
        rm = size(obj, 1);
      else
        rm = size(obj, 2);
      end
      res = arrdercontdef(right);
      res.m_size = [rm right.m_size(2)];
      res.m_derivs = permute(reshape(linsolve(obj, reshape(permute(right.m_derivs, [2,1,3]), ...
                                                   [right.m_size(1) right.m_ndd.*right.m_size(2)]), opts), ...
                                     [rm right.m_ndd right.m_size(2)]),[2,1,3]);
    end
  end
end
% $Id: linsolve.m 4790 2014-10-07 17:12:11Z willkomm $
function s = loadobj(s)
  if ~isa(s, 'arrdercontdef')
    s = class(s, 'arrdercontdef');
  end
  set(s, 'NumberOfDirectionalDerivatives', s.m_ndd);
end
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = log(obj)
  obj = unopFlat(obj, @log);
end
% $Id: log.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = lt(obj, v)
  res = cmpop(obj, v, @lt);
end
% $Id: lt.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function [obj, mi] = max(obj)
  [mv, mi] = max(obj.m_derivs{1});
  for i=1:obj.m_ndd
    obj.m_derivs{i} = obj.m_derivs{i}(mi);
  end
end
% $Id: max.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = mean(obj, k)
  if nargin < 2
    k = adimat_first_nonsingleton(obj);
  end
  if admIsOctave() && k+1 > length(size(obj.m_derivs))
  else
    obj.m_derivs = mean(obj.m_derivs, k+1);
    obj.m_size = computeSize(obj);
  end
end
% $Id: mean.m 4829 2014-10-13 07:06:33Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function [obj, mi] = min(obj)
  [mv, mi] = min(obj.m_derivs{1});
  for i=1:obj.m_ndd
    obj.m_derivs{i} = obj.m_derivs{i}(mi);
  end
end
% $Id: min.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = minus(obj, right)
  obj = binopFlat(obj, right, @minus);
end
% $Id: minus.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = minusdd(obj, right)
  obj = binopFlatdd(obj, right, @minus);
end
% $Id: minusdd.m 4393 2014-06-03 08:18:50Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = minusddes(obj, right)
  obj = binopFlatddes(obj, right, @minus);
end
% $Id: minusddes.m 4393 2014-06-03 08:18:50Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = minusdv(obj, right)
  obj = binopFlatdv(obj, right, @minus);
end
% $Id: minusdv.m 4393 2014-06-03 08:18:50Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function res = mldivide(obj, right)
  if isobject(obj)
    warning('why here? This probably shows a bug');
    obj = binopLoop(obj, right, @mldivide);
  else
    if isscalar(obj)
      res = ldivide(obj, right);
    else
      %    fprintf(admLogFile, 'mldivide: (%dm x %dn) \\ (%dm x %dn x %dndd)\n',...
      %            size(obj,1), size(obj,2), size(right,1), size(right,2), right.m_ndd);
      res = arrdercontdef(right);
      res.m_size = [size(obj, 2) right.m_size(2)];
      res.m_derivs = permute(reshape(obj \ reshape(permute(right.m_derivs, [2 1 3]), ...
                                                   [right.m_size(1) right.m_ndd.*right.m_size(2)]),...
                                     [size(obj, 2) right.m_ndd right.m_size(2)]),[2,1,3]);
    end
  end
end
% $Id: mldivide.m 4358 2014-05-28 11:13:35Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = mrdivide(obj, right)
  if isobject(right)
    warning('why here? This probably shows a bug');
    obj = binopLoop(obj, right, @mrdivide);
  else
    if isscalar(right)
      obj = binopFlat(obj, right, @rdivide);
    else
      warning('adimat:mrdivide', '%s', 'optimal version not implemented yet, use \ instead');
      obj = binopLoop(obj, right, @mrdivide);
    end
  end
end
% $Id: mrdivide.m 4823 2014-10-09 20:43:55Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function res = mtimes(obj, right)
  if isscalar(obj) || isscalar(right)
    res = times(obj, right);
  else
    % pref = getpref('adimat', 'optimizeloopthreshold', 0.9);
    if isobject(obj)
      if isobject(right)
        pref = 1.1;
%        fprintf(admLogFile, 'mtimes: (%dm x %dn x %dndd) * (%dm x %dn x %dndd)\n',...
%                size(obj,1), size(obj,2), obj.m_ndd, size(right,1), size(right,2), right.m_ndd);
        if obj.m_size(1) < obj.m_ndd.*pref || right.m_size(2) < obj.m_ndd.*pref
          res = arrdercontdef(obj);
          res.m_size = [obj.m_size(1) right.m_size(2)];
          res.m_derivs = zeros([obj.m_ndd res.m_size]);
          if obj.m_size(1) < right.m_size(2).*0.9
            for k=1:obj.m_size(1)
              ddr = bsxfun(@times, reshape(obj.m_derivs(:,k,:), [obj.m_ndd obj.m_size(2)]), right.m_derivs);
              res.m_derivs(:,k,:) = sum(ddr, 2);
            end
          else
            for k=1:right.m_size(2)
              ddr = bsxfun(@times, obj.m_derivs, reshape(right.m_derivs(:,:,k), [obj.m_ndd 1 right.m_size(1)]));
              res.m_derivs(:,:,k) = sum(ddr, 3);
            end
          end
        else
          res = binopLoop(obj, right, @mtimes);
        end
      else
%        fprintf(admLogFile, 'mtimes: (%dm x %dn x %dndd) * (%dm x %dn)\n',...
%                size(obj,1), size(obj,2), obj.m_ndd, size(right,1), size(right,2));
        res = arrdercontdef(obj);
        res.m_size = [obj.m_size(1) size(right, 2)];
        res.m_derivs = reshape(reshape(obj.m_derivs, [obj.m_ndd.*obj.m_size(1) obj.m_size(2)]) * right,...
                               [res.m_ndd res.m_size]);
      end
    else
%      fprintf(admLogFile, 'mtimes: (%dm x %dn) * (%dm x %dn x %dndd)\n',...
%              size(obj,1), size(obj,2), size(right,1), size(right,2), right.m_ndd);
      pref = 50;
      if right.m_size(2) < right.m_ndd.*pref
        res = arrdercontdef(right);
        res.m_size = [size(obj, 1) right.m_size(2)];
        res.m_derivs = zeros([right.m_ndd res.m_size]);
        ot = obj.';
        for k=1:right.m_size(2)
          ddr = right.m_derivs(:,:,k) * ot;
          res.m_derivs(:,:,k) = ddr;
        end
      else
        res = binopLoop(obj, right, @mtimes);
      end
    end
  end
end
% $Id: mtimes.m 4358 2014-05-28 11:13:35Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2015 Johannes Willkomm 
%
function n = ndims(obj)
  n = length(obj.m_size);
end
% $Id: ndims.m 4863 2015-02-07 15:37:52Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = ne(obj, v)
  res = cmpop(obj, v, @ne);
end
% $Id: ne.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = numel(obj, varargin)
%  fprintf('arrdercontdef.numel: %s\n', num2str(size(obj)));
%  disp(varargin);
  if nargin < 2
    res = 1;
    return
  end
  s = varargin{1};
  tinfo = whos('s');
  if strcmp(tinfo.class, 'magic-colon') || (ischar(varargin{1}) && (varargin{1}==':'))
    res = obj.m_ndd(1);
  else
    res = length(varargin{1});
  end
%  fprintf('arrdercontdef.numel: %d\n', res);
end
% $Id: numel.m 4686 2014-09-18 09:59:43Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = permute(obj, order)
  obj.m_derivs = permute(obj.m_derivs, [1 order+1]);
  msz = [obj.m_size ones(1, length(order)-length(obj.m_size))];
  obj.m_size = msz(order);
end
% $Id: permute.m 4895 2015-02-16 13:10:12Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = plus(obj, right)
  obj = binopFlat(obj, right, @plus);
end
% $Id: plus.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = plusdd(obj, right)
  obj = binopFlatdd(obj, right, @plus);
end
% $Id: plusdd.m 4392 2014-06-03 07:41:31Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = plusddes(obj, right)
  obj.m_derivs = obj.m_derivs + right.m_derivs;
end
% $Id: plusddes.m 4585 2014-06-22 08:06:21Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = plus(obj, right)
  obj = binopFlatdv(obj, right, @plus);
end
% $Id: plusdv.m 4392 2014-06-03 07:41:31Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = rdivide(obj, right)
  obj = binopFlat(obj, right, @rdivide);
end
% $Id: rdivide.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = rdividedv(obj, right)
  obj = binopFlatdv(obj, 1 ./ right, @times);
end
% $Id: rdividedv.m 4414 2014-06-04 06:22:28Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = real(obj)
  obj = unopFlat(obj, @real);
end
% $Id: real.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = repmat(obj, varargin)
  repv = [varargin{:}];
  repvd = [1 repv];
  obj.m_derivs = repmat(obj.m_derivs, repvd);
  obj.m_size = [obj.m_size ones(1, length(repv)-length(obj.m_size))] .* repv;
end
% $Id: repmat.m 4291 2014-05-22 11:07:49Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2011,2012,2013,2015 Johannes Willkomm 
function obj = reshape(obj, varargin)
  epos = cellfun('isempty', varargin);
  if any(epos)
    eppos = find(epos);
    varargin{eppos} = prod(obj.m_size) ./ prod(cat(1, varargin{~epos}));
  end
  obj.m_size = adimat_normalize_size([varargin{:}]);
  obj.m_derivs = reshape(obj.m_derivs, [obj.m_ndd obj.m_size]);
end
% $Id: reshape.m 4949 2015-03-02 13:08:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = rot90(obj, k)
  if nargin < 2
    k = 1;
  end
  k = mod(k, 4);
  if k < 0, k = k + 4; end
  switch k
   case 0
   case 1
    obj = flipud(obj.');
   case 2
    obj = flipud(fliplr(obj));
   case 3
    obj = flipud(obj).';
  end
end
% $Id: rot90.m 4323 2014-05-23 09:17:16Z willkomm $
function s = saveobj(s)
end
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = sign(obj)
  [res] = sign(admGetDD(obj, 1));
end
% $Id: sign.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = sin(obj)
  obj = unopFlat(obj, @sin);
end
% $Id: sin.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function [varargout] = size(obj, varargin)
  if nargin > 1
    varargout{1} = obj.m_size(varargin{1});
  else
    if nargout <= 1
      varargout{1} = obj.m_size;
    else
      for i=1:nargout-1
        varargout{i} = obj.m_size(i);
      end
      varargout{nargout} = prod(obj.m_size(nargout:end));
    end
  end
end
% $Id: size.m 3883 2013-09-26 10:59:15Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = sqrt(obj)
  obj = unopFlat(obj, @sqrt);
end
% $Id: sqrt.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = subsasgn(obj, ind, rhs)
  switch ind(1).type
   case '()'
    subs = ind(1).subs;

    if ~isa(obj, 'arrdercontdef')
      t(subs{:}) = zeros(size(rhs));
      obj = arrdercontdef(t);
    end
    sz = obj.m_size;

    if isfloat(rhs) && isequal(size(rhs), [0 0])
      % delete operation

      if length(subs) == 1
        isr = isrow(obj);
        isv = isvector(obj);
        if isv
          if isr
            subs = [{':'} subs];
          end
        else
          obj.m_size = [1 prod(obj.m_size)];
          obj.m_derivs = reshape(obj.m_derivs, [obj.m_ndd obj.m_size]);
          subs = [{':'} subs];
        end
        obj.m_derivs(:, subs{:}) = [];
        obj.m_size = computeSize(obj);
      else
        if ~admIsOctave
          if length(subs) < length(obj.m_size)
            obj.m_size = [obj.m_size(1:length(subs)-1) prod(obj.m_size(length(subs):end))];
            obj.m_derivs = reshape(obj.m_derivs, [obj.m_ndd obj.m_size]);
          end
        end
        obj.m_derivs(:, subs{:}) = [];
        obj.m_size = computeSize(obj);
      end
      
    else
    if length(subs) == 1

      ind1 = subs{1};

      if islogical(ind1)
        numInd1 = sum(ind1(:));
        maxInd1 = numel(ind1);
      elseif ischar(ind1) && isequal(ind1,':')
        numInd1 = prod(sz);
        maxInd1 = numInd1;
      elseif isempty(ind1)
        numInd1 = 0;
        maxInd1 = 0;
      else
        numInd1 = numel(ind1);
        maxInd1 = max(ind1(:));
      end
      
      if isa(rhs, 'arrdercontdef')
        rhsd = rhs.m_derivs;
        rsz = rhs.m_size;
        risM = length(rsz) == 2;
        if risM && rsz(1) == 1 && rsz(2) == 1
          rhsd = repmat(rhsd, [1 numInd1]);
        end
      else
        rhsd = rhs; % must be scalar
      end
      
      if maxInd1 > prod(sz)
        % enlarging
        trial = reshape(obj.m_derivs(1, :), sz);
        trial(ind1) = rhsd(1, :);
        
        szt = size(trial);
        topinds = mat2cell(szt', ones(length(szt), 1));
        obj.m_derivs(1, topinds{:}) = 0;
        
        obj.m_derivs(:, ind1) = rhsd(:,:);
        obj.m_size = szt;
      else
        % not enlarging
        obj.m_derivs(:, ind1) = rhsd(:,:);
      end
        
    elseif length(subs) >= 2
      % regular, two or more indices
      
      if isa(rhs, 'arrdercontdef')
        rhsd = rhs.m_derivs;
      else
        rhsd = repmat(reshape(rhs, [1 size(rhs)]), [obj.m_ndd ones(1,length(subs))]);
      end

      if isscalar(rhs)
        for k=1:length(subs)
          indk = subs{k};
          if islogical(indk)
            numInd(k) = sum(indk(:));
          elseif ischar(indk) && isequal(indk,':')
            if k==length(subs) % last one
              numInd(k) = prod(sz(k:end));
            else
              numInd(k) = sz(k);
            end
          elseif isempty(indk)
            numInd(k) = 0;
          else % numeric
            numInd(k) = numel(indk);
          end
        end
        rhsd = repmat(rhsd, [1 numInd]);
      end
      
      dds = obj.m_derivs;
      dds(1:obj.m_ndd, subs{:}) = rhsd;
      obj.m_derivs = dds;
    
      obj.m_size = computeSize(obj);
    
    else
      % length(subs) > 2
      error('should never happen')
      obj = subsasgn_old(obj, ind, rhs);
    
    end
    end
    
   case '{}'
    if length(ind(1).subs) > 1
      error('multiple indices in {} not allowed');
    end
    ind1 = ind(1).subs{1};
    if length(ind) > 1
      for i=1:length(ind1)
        k = ind1(i);
        dd = admGetDD(obj, k);
        dd = subsasgn(dd, ind(2:end), rhs);
        obj.m_derivs(k, :) = dd(:);
      end
    else
      csz = size(obj);
      rsz = size(rhs);
      if ~isequal(csz, rsz)
        error('adimat:arrdercontdef:subsasgn:sizeMismatch', ...
              ['when setting a n-times direction, the size must ' ...
               'be the same as the current size (%s), but it is %s'], ...
              mat2str(csz), mat2str(rsz));
      end
      for i=1:length(ind1)
        k = ind1(i);
        obj.m_derivs(k, :) = rhs(:);
      end
    end
    %    end
   case '.'
    switch ind.subs
     case 'm_ndd'
      obj.m_ndd = rhs;
    end
  end
end
% $Id: subsasgn.m 4781 2014-10-06 21:51:53Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = subsasgn_old(obj, ind, rhs)
  switch ind(1).type
   case '()'
    subs = ind(1).subs;
    dind = ind;
    if ~(length(subs) == 1 && ischar(subs{1}) && ischar(subs{1}) && isequal(subs{1}, ':'))
      dind(1).subs = {':', subs{:}};
    end
    if isa(rhs, 'arrdercontdef')
      ndd = rhs.m_ndd;
      rhsderivs = rhs.m_derivs;
      szr = size(rhs);
      szl = size(obj);
      szo = szl;
      if isempty(obj) && isa(obj, 'double')
        obj = arrdercontdef([]);
        ddr = reshape(rhsderivs(1,:), szr);
        ddl = subsasgn([], ind, ddr);
        szl = size(ddl);
        obj.m_size = szl;
        obj.m_derivs = zeros([ndd szl]);
      else
        ddl = reshape(obj.m_derivs(1,:), szl);
        ddr = reshape(rhsderivs(1,:), szr);
        ddl = subsasgn(ddl, ind, ddr);
        szl = size(ddl);
        obj.m_size = szl;
        if any(szl > szo)
          topind = mat2cell(szl, 1, ones(1, length(szl)));
          obj.m_derivs(1, topind{:}) = ddl(topind{:});
        end
      end
      szl = size(obj);
      for i=1:ndd
        ddl = reshape(obj.m_derivs(i,:), szl);
        ddr = reshape(rhs.m_derivs(i,:), szr);
        ddl = subsasgn(ddl, ind, ddr);
        obj.m_derivs(i,:) = ddl(:).';
      end
    else
      if isscalar(rhs)
        testobj = subsasgn(zeros(size(obj)), ind, 1);
        nass = sum(testobj(:));
        rhs = repmat(rhs, [1 nass 1]);
      end
      rhs = repmat(reshape(rhs, [1 size(rhs)]), [obj.m_ndd ones(1, length(size(rhs)))]);
      obj.m_derivs = subsasgn(obj.m_derivs, dind, rhs);
    end
    obj.m_size = computeSize(obj);
    varargout{1} = obj;
   case '{}'
    if length(ind(1).subs) > 1
      error('not allowed')
    end
    ind1 = ind(1).subs{1};
    if length(ind) > 1
      for i=1:length(ind1)
        k = ind1(i);
        dd = admGetDD(obj, k);
        dd = subsasgn(dd, ind(2:end), rhs);
        obj.m_derivs(k, :) = dd(:);
      end
    else
      csz = size(obj);
      rsz = size(rhs);
      if ~isequal(csz, rsz)
        error('adimat:arrdercontdef:subsasgn:sizeMismatch', ...
              ['when setting a n-times direction, the size must ' ...
               'be the same as the current size (%s), but it is %s'], ...
              mat2str(csz), mat2str(rsz));
      end
      for i=1:length(ind1)
        k = ind1(i);
        obj.m_derivs(k, :) = rhs(:);
      end
    end
    %    end
  end
end
% $Id: subsasgn_old.m 4239 2014-05-17 16:32:58Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function varargout = subsref(obj, ind)
%  fprintf('arrdercontdef.subsref: %s, nargout=%d\n', num2str(size(obj)),nargout);
%  disp(ind);
  switch ind(1).type
   case '()'
    subs = ind(1).subs;

    sz = obj.m_size;
    isM = length(sz) == 2;
    
    if length(subs) == 1

      ind1 = subs{1};

      if ischar(ind1) && isequal(ind1,':')
        numInd1 = prod(sz);
        obj.m_size = [numInd1, 1];
        obj.m_derivs = reshape(obj.m_derivs, [obj.m_ndd numInd1]);
      else
        if islogical(ind1)
          numInd1 = sum(ind1(:));
          if isM && sz(1) == 1
            obj.m_size = [1, numInd1];
          else
            obj.m_size = [numInd1, 1];
          end
        else
          numInd1 = numel(ind1);
          if isM && sz(1) == 1 && isvector(ind1)
            obj.m_size = [1, numInd1];
          elseif isM && sz(2) == 1 && isvector(ind1)
            obj.m_size = [numInd1, 1];
          else
            obj.m_size = size(ind1);
          end
        end

        obj.m_derivs = reshape(obj.m_derivs(:, ind1), [obj.m_ndd obj.m_size]);
      
      end
    else      

      numInds = length(ind(1).subs);
      jDim = numInds-1;
      helpSize = [obj.m_ndd sz(1:jDim) prod(sz(jDim+1:end))];
      ind(1).subs = [{':'} subs];
      obj.m_derivs = subsref(reshape(obj.m_derivs, helpSize), ind);
      obj.m_size = computeSize(obj);
    
    end
    varargout{1} = obj;
   
   case '{}'
    if length(ind(1).subs) > 1
      error('adimat:arrdercontdef:subsref:multipleindexincurlybrace',...
            ['there are %d indices in the curly brace reference, but ' ...
             'only one is allowed'], length(ind(1).subs));,
    end
    cinds = ind(1).subs{1};
    if isa(cinds, 'char') && isequal(cinds, ':')
      cinds = 1:obj.m_ndd;
    end
    selected = cell(length(cinds), 1);
    for i=1:length(cinds)
      selected{i} = admGetDD(obj, cinds(i));
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
    error('adimat:tseries:subsref:invalidsubsref', ...
          'Subsref type %s not allowed', ind(1).type);
    %    [varargout{1:nargout}] = subsref(struct(obj), ind);
  end
end
% $Id: subsref.m 4586 2014-06-22 08:06:33Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = sum(obj, k)
  if nargin < 2
    k = adimat_first_nonsingleton(obj);
  end
  obj.m_derivs = sum(obj.m_derivs, k+1);
  obj.m_size = computeSize(obj);
end
% $Id: sum.m 4268 2014-05-20 08:28:26Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = tan(obj)
  obj = unopFlat(obj, @tan);
end
% $Id: tan.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = times(obj, right)
  obj = binopFlat(obj, right, @times);
end
% $Id: times.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = timesdd(obj, right)
  obj = binopFlatdd(obj, right, @times);
end
% $Id: timesdd.m 4392 2014-06-03 07:41:31Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = timesddes(obj, right)
  obj = binopFlatddes(obj, right, @times);
end
% $Id: timesddes.m 4393 2014-06-03 08:18:50Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = timesdv(obj, right)
  obj = binopFlatdv(obj, right, @times);
end
% $Id: timesdv.m 4392 2014-06-03 07:41:31Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
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
% $Id: toDouble.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = toStruct(obj)
  res.m_derivs = obj.m_derivs;
  res.m_ndd = obj.m_ndd;
  res.m_size = obj.m_size;
  res.className = 'arrdercontdef';
end
% $Id: toStruct.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = transpose(obj)
  obj.m_derivs = permute(obj.m_derivs, [1 3 2]);
  obj.m_size = fliplr(obj.m_size);
end
% $Id: transpose.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm 
function obj = tril(obj, k)
  if nargin<2
    k = 0;
  end
  for i=1:min(obj.m_size(1),obj.m_size(1)-k)
    obj.m_derivs(:,i,max(1,i+1+k):end) = 0;
  end
end
% $Id: tril.m 4959 2015-03-03 08:35:00Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm 
function obj = triu(obj, k)
  if nargin<2
    k = 0;
  end
  for i=1:min(obj.m_size(1)+k, obj.m_size(2))
    obj.m_derivs(:,max(1,i+1-k):end,i) = 0;
  end
end
% $Id: triu.m 4959 2015-03-03 08:35:00Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = uminus(obj)
  obj = unopFlat(obj, @uminus);
end
% $Id: uminus.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = unopFlat(obj, handle, varargin)
  obj.m_derivs = handle(obj.m_derivs);
end
% $Id: unopFlat.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = unopLoop(obj, handle, varargin)
  res = cell(obj.m_ndd, 1);
  for i=1:obj.m_ndd
    dd1 = reshape(obj.m_derivs(i,:), [obj.m_size]);
    dd = handle(dd1, varargin{:});
    res{i} = reshape(full(dd), [1 size(dd)]);
  end
  obj.m_derivs = cat(1, res{:});
  obj.m_size = size(dd);
end
% $Id: unopLoop.m 4288 2014-05-21 13:35:23Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = unopLoopWO(handle, wo, varargin)
  obj = varargin{wo};
  res = cell(obj.m_ndd, 1);
  for i=1:obj.m_ndd
    dd1 = reshape(obj.m_derivs(i,:), [obj.m_size]);
    dd = handle(varargin{1:wo-1}, dd1, varargin{wo+1:end});
    res{i} = reshape(full(dd), [1 size(dd)]);
  end
  obj.m_derivs = cat(1, res{:});
  obj.m_size = size(dd);
end
% $Id: unopLoopWO.m 4796 2014-10-08 10:37:06Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = uplus(obj)
  obj = unopFlat(obj, @uplus);
end
% $Id: uplus.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = vertcat(obj, varargin)
  obj = cat(1, obj, varargin{:});
end
% $Id: vertcat.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = zero(obj, val)
  obj = obj.init(zeros(size(val)));
end
% $Id: zero.m 3862 2013-09-19 10:50:56Z willkomm $
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm
%
function obj = zerobj(obj)
  obj.m_derivs = zeros([obj.m_ndd obj.m_size]);
end
% $Id: zerobj.m 4591 2014-06-22 08:16:04Z willkomm $
end
end
