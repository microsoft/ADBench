function rout= deepcopy(rin)
% deepcopy -- Copy a structure replacing each numerical object with a zero
%   matrix of same size.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


   fname= fieldnames(rin);
   for i= 1: length(fname)
      curr= rin.(fname{i});
      if isstruct(curr)
         rout.(fname{i})= deepcopy(curr);
      elseif isnumeric(curr)
         if issparse(curr)
            rout.(fname{i})= sparse([],[],[], size(curr,1), size(curr,2));
         else
            rout.(fname{i})= zeros(size(curr));
         end
      elseif ischar(curr)
         rout.(fname{i}) = curr;
      elseif iscell(curr)
         rout.(fname{i})= cell(size(curr));
         warning('ADiMat:DeepCopyCellarray', 'Deepcopy: Creating empty cellarray for cellarray in structure.');
      else
         warning('ADiMat:DeepCopyUnknown', ...
                 'Deepcopy: Trying to copy member of class %s of a structure. Replacing with empty matrix [].', ...
                 class(curr));
         rout.(fname{i})= [];
      end
   end


