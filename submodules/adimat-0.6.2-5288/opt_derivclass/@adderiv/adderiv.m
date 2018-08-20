function g= adderiv(n,sz,mode)
%ADDERIV Construct a derivate-object for automatic differentiation.
%
% g= adderriv(adobj) Copies information from the adobj to the new
%     derivative object g. A lightweight copy is used, i.e., no directional
%     derivatives are copied. The meta information is copied, only.
%
% g= adderiv(ndd, sz, 'zeros') Creates a new derivative object with storage
%     for ndd many directional derivatives. Each directional derivative has
%     size sz storage allocated and is filled with zeros. The keyword 'zeros'
%     may be omited.
%
% g= adderiv(ndd, sz, 'sparse') The same as using 'zeros' but this time
%     a sparse datastructure is used.
%
% g= adderiv(ndd, sz, 'object') Uses copies of the object sz to stored in
%     every directional derivative.
%
% g= adderiv(ndd, sz, 'empty') Does not care about the data in sz. I.e.,
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
% Copyright 2014 Johannes Willkomm
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

persistent intval_exists

if isempty(intval_exists)
  intval_exists= (exist('intval')==2);
end

if intval_exists
  superiorto('intval');
end

if nargin== 0
   error('An adderiv object needs to know its number of directional derivatives.');
elseif nargin==1 && isa(n, 'adderiv')
   if n.dims==1
      g= struct('deriv', {cell(n.ndd, 1)}, 'dims', 1, 'ndd', n.ndd, 'left', n.left);
   else
      g= struct('deriv', {cell(n.ndd)}, 'dims', n.dims, 'ndd', n.ndd, 'left', n.left);
   end
   g=class(g, 'adderiv');
   return
elseif nargin==1 && isstruct(n)
   g= struct('deriv', {n.deriv}, 'dims', n.dims, 'ndd', n.ndd, 'left', n.left);
   g=class(g, 'adderiv');
   return
else
   if isempty(n)
      n= option('NumberOfDirectionalDerivatives');
   end
   if nargin==2
      mode= 'zeros';
   end
   switch length(n)
   case 1
      g.deriv= cell(n, 1);
      g.dims=1;
   case 2
      g.deriv= cell(n);
      g.dims=2;
   case 0
      g.deriv= cell(0, 1);
      g.dims= 0;
%   case 0
%      error('Zero-dimensional derivatives are not supported.');
   otherwise
      error('Higher dimensional (dim>2) derivatives are not supported.');
   end

   % Store the number of directional derivatives in the derivative.
   g.ndd= n;
   g.left = false;

   if g.dims==1
      switch mode
      case 'zeros'
         [g.deriv{:}]= deal(zeros(sz));
      case 'sparse'
         switch size(sz, 2)
         case 1
            [g.deriv{:}]= deal(sparse(sz, sz));
         case 2
            [g.deriv{:}]= deal(sparse(sz(1), sz(2)));
         otherwise
            error(['Sparse matrizes have a maximum of two dimensions. Current number of dimensions: ', num2str(length(sz))]);
         end
      case 'object'
         [g.deriv{:}]= deal(sz);
      case 'empty'
         % Create the skeleton only.
      otherwise
         error(['Unknown mode modifier: "',mode,'"']);
      end;
   else
      switch mode
      case 'zeros'
         [g.deriv{:,:}]= deal(zeros(sz));
      case 'sparse'
         switch size(sz, 2)
         case 1
            t= sparse(sz, sz);
         case 2
            t=sparse(sz(1), sz(2));
         otherwise
            error(['Sparse matrizes have a maximum of two dimensions. Current number of dimensions: ', num2str(length(sz))]);
         end
         [g.deriv{:,:}]= deal(t);
      case 'object'
         [g.deriv{:,:}]= deal(sz);
      case 'empty'
         % Create the skeleton only
      otherwise
         error(['Unknown mode modifier: "',mode,'"']);
      end;
   end % if g.dims==1
   g= class(g, 'adderiv');
end

% vim:sts=3:
