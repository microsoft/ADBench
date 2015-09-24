function g= madderiv(n,sz,mode)
%MADDERIV Construct a derivate-object for automatic differentiation.
%
% g= madderriv(adobj) Copies information from the adobj to the new
%     derivative object g. A lightweight copies is used, i.e., no directional
%     derivatives are copied. The meta information is copied, only.
%
% g= madderiv(ndd, sz, 'zeros') Creates a new derivative object with storage
%     for ndd times directional derivatives. Each directional derivative has
%     size sz storage allocated and is filled with zeros. The keyword 'zeros'
%     may be omited.
%
% g= madderiv(ndd, sz, 'cond_sparse') The same as using 'zeros' but this time
%     a cond_sparse datastructure is used.
%
% g= madderiv(ndd, sz, 'object') Uses copies of the object sz to stored in
%     every directional derivative.
%
% g= madderiv(ndd, sz, 'empty') Does not care about the data in sz. I.e.,
%     sz can be []. This command initializes the metainformation only.
%
% This constructor can be used to initialize Hessains, too. ndd has to be
% twodimensional then.
%
% If ndd is [], then the number of directional derivatives is read using the 
% option-method.
%
% It is currently not implemented to use derivative object of higher order 
% than two.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

persistent intval_exists

if isempty(intval_exists)
  intval_exists= exist('intval.m', 'file')==2;
end

if intval_exists
  superiorto('intval');
end

if nargin== 0
   error('An madderiv object needs to know its number of directional derivatives.');
elseif nargin==1 && isa(n, 'madderiv')
   g= struct('deriv', [], 'dims', n.dims, 'ndd', n.ndd, 'sz', n.sz);
   g= class(g, 'madderiv');
   return
else
   if isempty(n)
      n= option('NumberOfDirectionalDerivatives');
   end
   if nargin==2
      mode= 'zeros';
   end
   g.deriv= [];
   g.dims= length(n);
   if g.dims==1
      g.ndd= [1 n];
   else
      g.ndd= n;
      if n(1)==1
         % Allthough a 2D-vector is given, it is a 1D deriv. obj. only.
         g.dims= 1;
      end
   end
   g.sz= [0, 0];
   
   if strcmp(mode,'zeros') || strcmp(mode,'sparse')
      switch size(sz, 2)
         case 1
            g.deriv= spalloc(sz*g.ndd(1), sz*g.ndd(2), 0);
            g.sz= [sz, sz];
         case 2
            g.deriv= spalloc(sz(1)*g.ndd(1), sz(2)*g.ndd(2),0);
            g.sz= sz;
         otherwise
            error('Sparse matrizes have a maximum of two dimensions. Current number of dimmensions: %d', length(sz));
         end
   else
      switch mode
         case 'object'
            g.deriv= repmat(sz, g.ndd);
            g.sz= size(sz);
         case 'direct'
            g.deriv= sz;
            if prod(size(sz))
              g.sz= size(sz)./ g.ndd;
            else
              g.sz= size(sz);
            end
         case 'empty'
            % Create the skeleton only. 
         otherwise
            error('Unknown mode modifier: ''%s''', mode);
         end;
   end;
   g= class(g, 'madderiv');
end

% vim:sts=3:

