function varargout=get(g, arg)
%MADDERIV/GET Get the derivative or option.
%
%  varargout= get(g, {i}); Gets the i-th directional derivative of the 
%       first order derivative object g. If i is scalar, then the curly
%       parentheses may be omited. If i is a vector, then the returned
%       value depends on the number of results in call to get(). E.g.:
%       
%       Let g_b contain five directional derivative each n x m -matrizes,
%       then 
%
%       res= get(g_b, {[2:4]}); 
%
%       returns a n x (m* 3) object. This is exactly the same as calling
%       
%       [get(g_b, {[2:4]})]
%
%       For a call:
%
%       [dd1, dd2, dd3]= get(g_b,{[2:4]});
%
%       the result dd1 is assigned the 2nd directional derivative of 
%       g_b, dd2 the third and so on.
%
%  varargout= get(g, {i,j}); Gets the i,j-th directional derivative of the 
%       second order derivative object g. i and j have to be vectors, if
%       multiple directional derivatives are expected.
%
%  value= get(g, 'optionname'); Get the current value of the ad-option
%       specified by optionname or the content of the derivative object.
%       Valid entries for optionname are:
%       
%     'direct':
%         Returns the complete contents of the derivative object. If
%         g is a first order derivative object (a gradient), then this
%         option returns the horizontal concatenation of all
%         directional derivatives (the Jacobi matrix).
%         If g is a second order derivative object (a Hessian), then this
%         option returns a matrix of directional derivatives, where the 
%         directional derivatives are sorted as pictured:
%
%           d^2 g        d^2 g             ...           d^2 g
%         [ -----------  -----------                     ----------- ;
%           dg{1} dg{1}  dg{1} dg{2}                     dg{1} dg{m}
%
%           d^2 g                                        d^2 g
%           -----------                    ...           ----------- ;
%           dg{2} dg{1}                                  dg{2} dg{m}
%      
%              .                           .                .        ;
%              .                            .               .        ; 
%              .                             .              .        ;
%
%           d^2 g       d^2 g                            d^2 g
%           ----------- -----------        ...           ----------- ]  
%           dg{n} dg{1} dg{n] dg{2}                      dg{n} dg{m}
%
%     'NumberOfDirectionalDerivatives':
%         Returns the number of directional derivatives stored in the 
%         object g. The value is two-row vector. If g is a gradient, then
%         the value is of the form [1 ndd], where ndd is the number of 
%         directional derivatives. If g is a second order derivative object,
%         usually prefixed by 'h_', then the value returned is [n m], where
%         m is equal to ndd of the associated gradient object and n
%         normaly is equal to m. But does not have to!
%         The runtime class of ADiMat stores a default value of the number
%         of directional derivatives for creating new zero derivative 
%         objects using g_zeros and h_zeros. This value may be obtained by
%         get(g_dummy, 'NumberOfDirectionalDerivatives').
%
%    'ADiMatHome':
%         Get the base directory of the ADiMat installation. Internal use!
%         Do not change this path. It is needed to find the adimat-
%         executable.
%
%    'Version':
%         Returns the version number of ADiMat. This a float number,
%         where the digits in front of the dot give the version of 
%         ADiMat and the digit(s) at the right-hand side of the dot give
%         the revision. The release number is not obtainable from the 
%         option interface.
%         
%    'ClearAll':
%         Reset all modifieable options to their default values. Currently
%         this option sets the NumberOfDirectionalDerivatives to zero only.
%         This allows the creation of derivative objects with a different
%         number of directional derivatives. Be warned: The combination of
%         derivative object containing distinct numbers of direct. derivs.
%         is not supported and will not work. Use get(g, 'direct') to get
%         the all directional derivatives of a derivative object and 
%         combine them with another derivative objects contents. After
%         that you may store the result in a derivative object using 
%         newderivative_object=set(newderivative_object, 'direct', result)
%         Make sure, that the newderivative_object has the needed number
%         of directional derivatives and the objects stored in 
%         newderivative_object have the appropriate size. I.e. 
%         size(result)==get(newderivative_object, ...
%            'NumberOfDirectionalDerivatives').*size(newderivative_object{1})
%
%    'DerivativeClassName':
%         Returns the name of derivative class used as a string. This 
%         value may be used to distinguish between different implementations
%         of the derivative class. Although all derivative classes should
%         implement the same functionality, there may be features added to 
%         more recent derivative classes, that are missing in former ones.
%         
%    'DerivativeClassVersion':
%         Returns the version number of the derivative class.
%
%    'DerivativeClassKind':
%         Returns a string concatenating the name and the version of the
%         derivative class. This option is of informational purpose only.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if (isa(arg, 'double')&& size(arg)== [1 1])|| ...
  (isa(arg, 'char')&& arg(1)== ':')
   arg= {arg};
end

if isa(arg, 'char')
   switch arg
      case 'direct'
         varargout{1}= g.deriv;
      case {'NumberOfDirectionalDerivatives', 'ndd'}
         varargout{1}= prod(g.ndd);
      case 'nddraw'
         varargout{1}= g.ndd;
      case {'ObjSize', 'size', 'Size'}
         varargout{1}= g.sz;
      otherwise
         res= option(arg);
         if nargout>0
            varargout= {res};
         end
   end
   return
elseif isa(arg, 'cell')  % Copied from subsref.m
   if g.dims==1
      ind= arg{1};
      if ischar(ind) && ind==':'
         if nargout==g.ndd(2)
            varargout= mat2cell(g.deriv, ones(1,g.ndd(1))*g.sz(1), ...
                     ones(1,g.ndd(2))* g.sz(2));
         else
            varargout{1}= g.deriv;
         end
      elseif max(ind)<= g.ndd(2)
         numind= length(ind);
         index= [repmat(ind(:)- 1, 1, g.sz(2))* g.sz(2)+ ...
            repmat(1: g.sz(2), numind, 1)]';
         index= index(:);
         if nargout==length(ind)
            varargout= mat2cell(g.deriv(:,index'), g.sz(1), ...
                  ones(1, numind)* g.sz(2));
         else
            tempout=spalloc(g.sz(1), g.sz(2)* length(ind), ...
                  ceil(prod(g.sz)* length(ind)/3));
            tempout(:)= g.deriv(:,index');
            varargout{1}= tempout;
         end
      else
         error('Index %d out of range 1: %d', max(ind), g.ndd(2));
      end
   else
      error('Getting of contents is not supported yet.');
%      if length(arg)<2
%         error('Need two indices to adress twodimensional derivative.');
%      end
%      ind= {arg{1:2}};
%      if (isa(ind{1}, 'char') & (ind{1}==':'))
%         ind{1}= 1:g.ndd(1);
%      elseif max(ind{1})> g.ndd(1) 
%         error(sprintf('First index %d out of range 1: %d', max(ind{1}), g.ndd(1)));
%      end
%      if (isa(ind{2}, 'char') & (ind{2}==':'))
%         ind{2}= 1:g.ndd(2);
%      elseif max(ind{2})>g.ndd(2)
%         error(sprintf('Second index %d out of range 1: %d', max(ind{2}), g.ndd(2)));
%      end
%      varargout= {g.deriv{ind{:}}};
   end
else
   error('Invalid argument to madderiv.get()-method.');
end

% vim:sts=3:
