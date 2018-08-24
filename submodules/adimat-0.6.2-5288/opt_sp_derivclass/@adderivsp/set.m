function g=set(g, arg, varargin)
%ADDERIV/SET -- Set the derivative or global option.
%
%   g= set(g, {i}, A); Sets the i-th entry of g to A and returns 
%       the modified g. Make sure, that size(A)== size(g{1}).
%
%   g= set(g, {range,range}, A, B, ...); Sets the entries specified by the 
%       ranges of g to the values of A, B, ... . The number of objects 
%       specified by the range has to equal to the number of inputs A,B,...
%
%   g= set(g, 'optionname', newval); Sets the global option to the newval.
%       Beware this heavily influences the behaviour of the ADiMat runtime
%       class. Be sure to know what you are doing. This method is for
%       experts use only!
%       Available options for setting are:
%
%     'direct':
%       Set the values of g in one sweep. Have a look at get(g,'direct')
%       to find out how newvalue has to look like. g needs to be preallocated
%       and size(newval)==size(g{1}).* get(g, 'NumberOfDirectionalDerivatives')
%
%     'NumberOfDirectionalDerivatives':
%       Set the number of directional derivatives to newval. This 
%       option sets the number of directional derivatives, that is used
%       for creating zero derivative objects using g_zeros and h_zeros.
%       Setting a new value is possible only after clearing all options
%       or during the first use of the ADiMat runtime system. Be sure to
%       know what you are doing!
%
%   Hint: set(g, ':', value) is not valid!
%
%   All set-operations may be applied to single and two-dimensional 
%   derivative objects.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if isa(arg, 'double') && size(arg)== [1 1]
   arg= {arg};
end

if isa(arg, 'char')
   switch arg 
      case 'deriv'
         g.deriv = varargin{1};
      case 'left'
         g.left = varargin{1};
      case 'direct'
         sz= size(g.deriv{1});
         src= varargin{1};
         if g.dims==1
            if isequal(sz.* [1, g.ndd], size(src))
               sel= 1: sz(2);
               for c=1 : g.ndd
                  g.deriv{c}= cond_sparse(src(:, sel+sz(2)*(c-1)));
               end
            else
               expect= sz.* [1, g.ndd];
               error('The size of directional derivatives matrix to set is incompatible to number of elements expected. Expected: %dx%d, supplied: %dx%d.', ...
                   expect(1), expect(2), size(src,1), size(src,2));
            end
         else
            if isequal(sz.* g.ndd, size(src))
               sel1= 1: sz(1);
               sel2= 1: sz(2);
               for c1= 1: g.ndd(1)
                 for c2=1 : g.ndd(2)
                    g.deriv{c1,c2}= cond_sparse(src(sel1+ sz(1)* (c1-1), ...
                        sel2+sz(2)*(c2-1)));
                  end
               end
            else
               expect= sz.* g.ndd;
               error('The size of directional derivatives matrix to set is incompatible to number of elements expected. Expected: %dx%d, supplied: %dx%d.', ...
                   expect(1), expect(2), size(src,1), size(src,2));
            end
         end
      otherwise
         option(arg, varargin{1});
   end
elseif isa(arg, 'cell')
   if g.dims==1
      if size(arg,2)== 1
         if all(arg{1}<= g.ndd)
             [g.deriv{arg{:}}]= deal(varargin{:});
         else
            error(sprintf('Index %d:%d out of range 1: %d', min(arg{1}), ...
                   max(arg{1}), g.ndd));
         end
      else
         error('Use one dimensional index to address one dimensional derivative object!');
      end
   else
      if size(arg,2)==2
         if [arg{1:2}]<= [g.ndd(:)]'
            g.deriv{arg{1:2}}= varargin{:};
         else
            error(sprintf('Index {%d:%d, %d:%d} out of range {1:%d, 1:%d}', ...
                  min(arg{1}),max(arg{1}),min(arg{2}),max(arg{2}), ...
                  g.ndd(1), g.ndd(2)));
         end
      else
         error('Two-dimensional derivative objects have to be addressed using two indeces.');
      end
   end
else
   error('Invalid argument to adderivsp/set().');
end


