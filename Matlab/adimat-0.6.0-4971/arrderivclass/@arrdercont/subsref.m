% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function varargout = subsref(obj, ind)
%  fprintf('arrdercont.subsref: %s, nargout=%d\n', num2str(size(obj)),nargout);
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
      error('adimat:arrdercont:subsref:multipleindexincurlybrace',...
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
