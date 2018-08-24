function varargout = adimat_diff_min2(varargin)

  varargout{2} = min(varargin{2},varargin{4});
  ndd = size(varargin{1},1);
  tmp1 = varargout{2} == varargin{2};
  tmp2 = varargout{2} == varargin{4};
  ties = tmp1 & tmp2;
  if any(ties(:))
     warning('adimat:min:ties', 'There are %d ties in the min(x, y) evaluation.', sum(ties(:)));
  end
  if isscalar(varargin{2})
    varargout{1} = varargin{3};
    if any(tmp1(:))
      for i=1:ndd
        varargout{1}(i, tmp1)= varargin{1}(i); 
      end
    end
    if any(ties(:))
      for i=1:ndd
        varargout{1}(i, ties) = (varargin{1}(i) + varargin{3}(i, ties)) .* 0.5;
      end
    end
  elseif isscalar(varargin{4})
    varargout{1} = varargin{1};
    if any(tmp2(:))
      for i=1:ndd
        varargout{1}(i, tmp2)= varargin{3}(i); 
      end
    end
    if any(ties(:))
      for i=1:ndd
        varargout{1}(i, ties) = (varargin{1}(i, ties) + varargin{3}(i)) .* 0.5;
      end
    end
  else
    varargout{1} = varargin{3};
    if any(tmp1(:))
      varargout{1}(:, tmp1)= varargin{1}(:, tmp1); 
    end
    if any(ties(:))
      varargout{1}(:, ties) = (varargin{1}(:, ties) + varargin{3}(:, ties)) .* 0.5;
    end
  end

end
% automatically generated from $Id: derivatives-vdd.xml 5034 2015-05-20 20:03:39Z willkomm $
