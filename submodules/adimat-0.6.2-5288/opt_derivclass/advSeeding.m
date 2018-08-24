function [g_object, lddu]=advSeeding(g_object, coloring, varargin)
  % advSeeding - apply an advanced seeding to the object in g_object.
  %
  % Advanced seeding needs a coloring pattern of the derivative's data
  % which is usually known through structure of the problem or by evaluating
  % the Jacobian once and then applying color() on the Jacobian which
  % gives the coloring of the columns in the Jacobian.
  %
  % This function checks, that in the derivative object g_object is enough
  % room for max(coloring) directional derivatives and computes the 
  % seeding with respect to the coloring information. 
  %
  % Several parameters may be specified as tuppels in the varargin. These
  % are:
  %
  % 'startdd', n : where n gives the first directional derivative to use
  %                for the "colored" seeding. The number of directional
  %                derivatives (ndd) storeable in g_object needs to be
  %                ndd(g_object)>= n+max(coloring)
  %
  % 'object_size', [n, m]: gives the size of the object this derivative
  %                object is associated to. The size may be 2D only.
  %
  % 'seeding_size', [n, m]: gives the size of the object during seeding.
  %                The object will be transformed to the size appropiate
  %                for g_object before storing it in g_object. In most
  %                applications seeding_size==object_size, which is the 
  %                default.
  %
  % 'permute_order', [n m p]: The compressed directional derivatives
  %                may be transposed before they are stored in the 
  %                derivative object. For this the compressed directional
  %                derivatives are reshaped to the shape given 
  %                prepermute_shape (see below) where ndim(prepermute_shape)
  %                has to be 2. A third dimension containig the number of 
  %                directional derivatives is added. To transpose each
  %                directional derivative give 'premute_order', [2 1 3].
  %                The default is not transpose.
  %
  % 'prepermute_shape', [n m]: Before permuting the dimension of the
  %                directional derivatives object, one may resize it. 
  %                Give the 2D-shape of the object as argument here,
  %                before it is permuted.

% !!! This function needs adimat-0.4-r8 or higher. !!!
% Copyright 2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

   startdd= 0;
   osize= size(g_object{1});
   permute_order= [1 2 3];
   n_dds= get(g_object, 'NumberOfDirectionalDerivatives');
   if nargin>2
      % Got parameters
      if mod(nargin,2)~=0
         error('Named arguments of advSeeding() have to be pairs.');
      end
      for c=1: 2: (nargin-2)
         switch varargin{c}
            case 'startdd' 
               startdd= varargin{c+1}-1;
            case 'object_size'
               osize= varargin{c+1};
            case 'seeding_size'
               ssize= varargin{c+1};
            case 'permute_order'
               permute_order= varargin{c+1};
            case 'prepermute_shape'
               preper_shape= varargin{c+1};
            otherwise
               warning('Unknown option "%s".', varargin{c});
         end
      end
   end

   if ~ exist('ssize')
      ssize= osize;
   end
   
   if ~ exist('preper_shape')
      preper_shape= ssize;
   end
   
   % Number of directional derivatives used by coloring.
   used_dd= max(coloring);
   if startdd+used_dd>n_dds(2)
      error('The number of directional derivatives (%d) needed for advanced seeding is greater than the number of available directional derivatives (%d).', startdd+used_dd, n_dds(2));
   end
   
   sza= prod(ssize); % Full grown Jacobian size
   fd= reshape(repmat([1: ssize(1)]', 1, ssize(2))', 1, sza);
   sd= repmat([0: ssize(2)-1], 1, ssize(1));
   l_col= length(coloring);
   prep_seeding= sparse(fd, coloring'+sd.*ssize(2), ...
     ones(1, l_col), ssize(1), used_dd* ssize(2), l_col);
   if isequal(preper_shape, osize) && isequal(permute_order, [1 2 3])
      direct_seeding= prep_seeding;
   else
      direct_seeding= sparse(reshape(permute(reshape(full(prep_seeding), ...
              [preper_shape, used_dd]), permute_order), ...
          osize(1), osize(2)* used_dd));
   end
   
   g_object= set(g_object, 'direct', direct_seeding);
  
   if nargout>1
      lddu= startdd+ used_dd;
   end
  
