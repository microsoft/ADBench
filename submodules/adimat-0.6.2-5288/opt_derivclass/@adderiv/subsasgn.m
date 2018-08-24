function g= subsasgn(g,i,varargin)
%ADDERIV/SUBSASGN Assign a value to the derivative object.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University, TU Darmstadt
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


switch i(1).type
case '{}'
   if g.dims==1
      if i(1).subs{1}<= g.ndd
         if size(i(1).subs,2)==1
            if size(i, 2)> 1
               g.deriv{i(1).subs{1}}= subsasgn(g.deriv{i(1).subs{1}}, i(2:end), full(varargin{:}));
            else
               g.deriv{i(1).subs{1}}= varargin{:};
            end 
         else
            ind= i(1).subs{1};
            i(1).subs= i(1).subs{2:end};
            g.deriv{ind}= subsasgn (g.deriv{ind}, i, varargin{:});
         end
      else
         error(sprintf('Index %d out of range 1: %d', i(1).subs{1}, g.ndd));
      end
   else
      if size(i(1).subs,2)==2
         if [i(1).subs{1:2}]<= [g.ndd(:)]'
            if size(i, 2)> 1
               g.deriv{i(1).subs{1:2}}= subsasgn(g.deriv{i(1).subs{1:2}}, i(2:end), varargin{:});
            else
               g.deriv{i(1).subs{1:2}}= varargin{:};
            end 
         else
            error(sprintf('Index %d out of range 1: %d', i(1).subs{1}, g.ndd));
         end
      else
         if size(i(1).subs,2)<2
            error('Two-dimensional derivative objects have to be addressed using two indeces.');
         end
         ind= i(1).subs{1:2};
         i(1).subs= i(1).subs{3:end};
         g.deriv{ind}= subsasgn (g.deriv{ind}, i, varargin{:});
      end
   end
case '()'
   if isa(varargin{1}, 'adderiv')
      if isa(g, 'adderiv')
        d1 = varargin{1}.deriv;
        dg = g.deriv;
         if g.dims==1 && varargin{1}.dims==1
            if g.ndd== varargin{1}.ndd
               for j= 1: g.ndd
                  dg{j}(i.subs{:})= d1{j};
               end
            else
               error(sprintf('Sizes of derivative objects disagree (lhs(%d)!=rhs(%d)).', g.ndd, varargin{1}.ndd));
            end
         elseif g.dims==2 && varargin{1}.dims==2
            if g.ndd== varargin{1}.ndd
               for c= 1: g.ndd(1)
                  for j= 1: g.ndd(2)
                     dg{c,j}(i.subs{:})= d1{c,j};
                  end
               end
            else
               error(sprintf('Sizes of derivative objects disagree (lhs(%d,%d)!=rhs(%d,%d)).', g.ndd(1), g.ndd(2), varargin{1}.ndd(1), varargin{1}.ndd(2)));
            end
         else
            error('Dimesions of derivative objects mismatch.');
         end
         g.deriv = dg;
      else
         g= adderiv(varargin{1});

         if g.dims==1
            for j= 1: g.ndd
               g.deriv{j}(i.subs{:})= varargin{1}.deriv{j};
            end
         else
            for c= 1: g.ndd(1)
               for j= 1: g.ndd(2)
                  g.deriv{c,j}(i.subs{:})= varargin{1}.deriv{c,j};
               end
            end   
         end
      end
   else
     if isfloat(varargin{1}) && isequal(size(varargin{1}), [0 0])
       for j= 1:prod(g.ndd)
         g.deriv{j}(i.subs{:})= [];
       end
     else
       for j= 1:prod(g.ndd)
         g.deriv{j}(i.subs{:})= varargin{1};
       end
     end
   end
case '.'
   if isa(varargin{1}, 'adderiv')
      if isa(g, 'adderiv')
         if g.dims==1 && varargin{1}.dims==1
            if g.ndd== varargin{1}.ndd
               for j= 1: g.ndd
                  g.deriv{j}= subsasgn(g.deriv{j}, i, varargin{1}.deriv{j});
               end
            else
               error(sprintf('Sizes of derivative objects disagree (lhs(%d)!=rhs(%d)).', g.ndd, varargin{1}.ndd));
            end
         elseif g.dims==2 && varargin{1}.dims==2
            if g.ndd== varargin{1}.ndd
               for c= 1: g.ndd(1)
                  for j= 1: g.ndd(2)
                     g.deriv{c,j}= subsasgn(g.deriv{c,j}, i, varargin{1}.deriv{c,j});
                  end
               end
            else
               error(sprintf('Sizes of derivative objects disagree (lhs(%d,%d)!=rhs(%d,%d)).', g.ndd(1), g.ndd(2), varargin{1}.ndd(1), varargin{1}.ndd(2)));
            end
         else
            error('Dimesions of derivative objects mismatch.');
         end
      else
         g= adderiv(varargin{1});

         if g.dims==1
            for j= 1: g.ndd
               g.deriv{j}= subsasgn(g.deriv{j}, i, varargin{1}.deriv{j});
            end
         else
            for c= 1: g.ndd(1)
               for j= 1: g.ndd(2)
                  g.deriv{c,j}= subsasgn(g.deriv{c,j}, i, varargin{1}.deriv{c,j});
               end
            end   
         end
      end
   else
      error('Right-hand side object has to be a derivative object.');
   end
otherwise
   error('Internal error.');
end

% vim:sts=3:
