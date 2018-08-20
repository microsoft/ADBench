function obj = subsasgn(obj, ind, rhs)
  switch ind(1).type
   case '()'
    if isa(rhs, 'tseries2')
      if isa(obj, 'double')
        obj = tseries2(obj, rhs.m_ord-1);
      end
      for k=1:obj.m_ord
        obj.m_series{k} = subsasgn(obj.m_series{k}, ind, rhs.m_series{k});
      end
    else
      obj.m_series = cellfun(@(x, y) subsasgn(x, ind, 0), obj.m_series, 'UniformOutput', false);
      obj.m_series{1} = subsasgn(obj.m_series{1}, ind, rhs);
    end
   case '{}'
    ind1 = ind(1).subs;
    if isa(rhs, 'tseries2')
      if length(ind) > 1
        obj.m_series(ind1{:}) = cellfun(@(x, y) subsasgn(x, ind(2:end), y), obj.m_series(ind1{:}), rhs.m_series, 'UniformOutput', false);
      else
        obj.m_series(ind1{:}) = rhs.m_series;
      end
    else
      if length(ind) > 1
        obj.m_series(ind1{:}) = cellfun(@(x) subsasgn(x, ind(2:end), rhs), ...
                                        obj.m_series(ind1{:}), 'UniformOutput', false);
      else
        csz = size(obj);
        rsz = size(rhs);
        if ~isequal(csz, rsz)
          error('adimat:tseries2:subsasgn:sizeMismatch', ...
                ['when setting a taylor coefficient, the size must ' ...
                 'be the same as the current size (%s), but it is %s'], ...
                mat2str(csz), mat2str(rsz));
        end
%        inner = tseries2.option('inner');
%        rhsv = inner(rhs);
        obj.m_series{ind1{:}} = rhs;
      end
    end
  end
end
