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
    objsz = obj.m_size;
    isM = length(objsz) == 2;

    ind(1).subs = {subs{:}, ':'};

    if length(subs) == 1

      ind1 = subs{1};

      if isnumeric(ind1)
        numInd1 = numel(ind1);
        if isM && objsz(1) == 1 && isvector(ind1)
          obj.m_size = [1, numInd1];
        elseif isM && objsz(2) == 1 && isvector(ind1)
          obj.m_size = [numInd1, 1];
        else
          obj.m_size = size(ind1);
        end
      elseif islogical(ind1)
        numInd1 = sum(ind1(:));
        if isrow(obj)
          obj.m_size = [1, numInd1];
        else
          obj.m_size = [numInd1, 1];
        end
      else % :
        numInd1 = prod(objsz);
        obj.m_size = [numInd1, 1];
      end

      obj.m_derivs = reshape(obj.m_derivs, [prod(objsz) obj.m_ndd]);
      obj.m_derivs = subsref(obj.m_derivs, ind);
      
    else
      
      numInds = length(subs);
      jDim = numInds-1;
      helpSize = [objsz(1:jDim) prod(objsz(jDim+1:end)) obj.m_ndd];
      obj.m_derivs = subsref(reshape(obj.m_derivs, helpSize), ind);
      obj.m_size = computeSize(obj);
    
    end

    obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size) obj.m_ndd]);
    varargout{1} = obj;
   
   case '{}'
    if length(ind(1).subs) > 1
      error('adimat:arrdercont:subsref:multipleindexincurlybrace',...
            ['there are %d indices in the curly brace reference, but ' ...
             'only one is allowed'], length(ind(1).subs));,
    end
    cinds = ind(1).subs{1};
    if (isa(cinds, 'char') && (cinds==':'))
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
          'Subsref type %s not allowed', ind(1).type)
    %    [varargout{1:nargout}] = subsref(struct(obj), ind);
  end
end
% $Id: subsref.m 4381 2014-05-30 09:54:09Z willkomm $
