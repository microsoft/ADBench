function varargout = subsref(obj, ind)
%  fprintf('tseries2.subsref: %s, nargout=%d\n', num2str(size(obj)),nargout);
  switch ind(1).type
   case '()'
    for k=1:obj.m_ord
      obj.m_series{k} = subsref(obj.m_series{k}, ind);
    end
    varargout{1} = obj;
   case '{}'
    if length(ind(1).subs) > 1
      error('adimat:tseries2:subsref:multipleindexincurlybrace',...
            ['there are %d indices in the curly brace reference, but ' ...
             'only one is allowed'], length(ind(1).subs));
    end
    cinds = ind(1).subs{1};
    if isa(cinds, 'char') && isequal(cinds, ':')
      selected = obj.m_series(1:obj.m_ord);
    else
      selected = obj.m_series(cinds);
    end
    if length(ind) > 1
      if length(selected) > 1
        error('adimat:tseries2:subsref:badcellreference',...
              '%s', 'Bad tseries2 coefficient reference operation');
      end
      [varargout{1:nargout}] = subsref(selected{1}, ind(2:end));
    else
      varargout = selected;
    end
   otherwise
    [varargout{1:nargout}] = subsref(struct(obj), ind);
  end
end
