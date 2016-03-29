classdef au_bsx
   % AU_BSX     A value class that implements a broadcastable data type
   %        The term "broadcast" comes from Python.
   %      EXAMPLE 
   %        a = rand(5,1); % Vector a
   %        B = rand(5,7); % Matrix B
   %        au_bsx(a) + B      % translates to bsxfun(@plus, a, B)
   %        max(au_bsx(a), B)  % translates to bsxfun(@max, a, B)
   %      One may wish to alias it, for even less typing:
   %        bsx = @(x) au_bsx(x)
   %        a + bsx(B)
   %      Notice that if any argument is broadcasting, the expression is.
   
   properties
      val
   end
   
   % Class methods
   methods
      function obj = au_bsx(c)
         % Construct a bsx object using the valficients supplied
         if isa(c,'au_bsx')
            obj.val= c.val;
         else
            obj.val = c;
         end
      end % bsx
%       function obj = set.val(obj,val)
%         obj.val = val;
%         val = val(ind(1):end);
%          else
%             obj.val = val;
%          end
%       end % set.val
      
      function c = double(obj)
         c = obj.val;
      end % double
      
      function str = char(obj)
         str = ['au_bsx['  num2str(obj.val) ']'];
      end % char
      
      function disp(obj)
         % DISP Display object in MATLAB syntax
         c = char(obj);
         disp(c)
      end % disp
      
%       function b = subsref(a,s)
%       end % subsref

      function r = runbsx(f, obj1,obj2)
         % PLUS  Implement obj1 + obj2 for bsx
         if ~isa(obj1,'au_bsx')
           r = bsxfun(f, obj1, obj2.val);
         elseif ~isa(obj2,'au_bsx')
           r = bsxfun(f, obj1.val, obj2);
         else
           r = bsxfun(f, obj1.val, obj2.val);
         end
      end % plus
      
      function r = plus(obj1,obj2)
         % PLUS  Implement obj1 + obj2 for bsx
         r = runbsx(@plus, obj1, obj2);
      end % plus
      
      function r = minus(obj1,obj2)
         r = runbsx(@minus, obj1, obj2);
      end % minus
      
      function r = times(obj1,obj2)
         r = runbsx(@times, obj1, obj2);
      end 
      function r = lt(obj1,obj2)
         r = runbsx(@lt, obj1, obj2);
      end
      function r = le(obj1,obj2)
         r = runbsx(@le, obj1, obj2);
      end
      function r = gt(obj1,obj2)
         r = runbsx(@gt, obj1, obj2);
      end
      function r = ge(obj1,obj2)
         r = runbsx(@ge, obj1, obj2);
      end
      function r = eq(obj1,obj2)
        r = runbsx(@eq, obj1, obj2);
      end
      
      function r = ne(obj1,obj2)
        r = runbsx(@ne, obj1, obj2);
      end
      
      % Right array divide
      function r = rdivide(obj1,obj2)
        r = runbsx(@rdivide, obj1, obj2);
      end
      
      % Left array divide
      function r = ldivide(obj1,obj2)
        r = runbsx(@ldivide, obj1, obj2);
      end
      
      % Array power
      function r = power(obj1,obj2)
        r = runbsx(@power, obj1, obj2);
      end
      
      function r = mpower(obj1,obj2)
         % MPOWER Implement obj1 ^ obj2 for bsx
         r = runbsx(@mpower, obj1, obj2);
      end % plus
      
      % Binary maximum
      function r = max(obj1,obj2)
        r = runbsx(@max, obj1, obj2);
      end
      
      % Binary minimum
      function r = min(obj1,obj2)
        r = runbsx(@min, obj1, obj2);
      end
      
      % Remainder after division
      function r = rem(obj1,obj2)
        r = runbsx(@rem, obj1, obj2);
      end
      
      % Modulus after division
      function r = mod(obj1,obj2)
        r = runbsx(@mod, obj1, obj2);
      end
      
      % Four-quadrant inverse tangent; result in radians
      function r = atan2(obj1,obj2)
        r = runbsx(@atan2, obj1, obj2);
      end
      
      % Four-quadrant inverse tangent; result in dgrees
      function r = atan2d(obj1,obj2)
        r = runbsx(@atan2d, obj1, obj2);
      end
      
      % Square root of sum of squares
      function r = hypot(obj1,obj2)
        r = runbsx(@hypot, obj1, obj2);
      end
      
      % Element-wise logical AND
      function r = and(obj1,obj2)
        r = runbsx(@and, obj1, obj2);
      end
      
      % Element-wise logical OR
      function r = or(obj1,obj2)
        r = runbsx(@or, obj1, obj2);
      end
      
      % Logical EXCLUSIVE OR
      function r = xor(obj1,obj2)
        r = runbsx(@xor, obj1, obj2);
      end
   end % methods 
end % classdef

