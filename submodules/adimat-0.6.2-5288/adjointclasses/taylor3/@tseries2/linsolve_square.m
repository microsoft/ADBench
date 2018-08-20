function res = linsolve_square(obj, right, opts)
  if isa(obj, 'tseries2')
    if isa(right, 'tseries2')
      sol = linsolve(obj.m_series{1}, right.m_series{1}, opts);
      res = tseries2(sol);
      % res.m_series{2} = obj.m_series{1} \ (right.m_series{2} - obj.m_series{2}*res.m_series{1});
      %
      % res.m_series{3} = 0.5 .* (obj.m_series{1} \ (right.m_series{3}...
      %                                      - 2.*obj.m_series{2}*res.m_series{2}...
      %                                      - obj.m_series{3}*res.m_series{1}));
      %
      % res.m_series{3} = (obj.m_series{1} \ (right.m_series{3}...
      %                                      - obj.m_series{2}*res.m_series{2}...
      %                                      - obj.m_series{3}*res.m_series{1}));

      for k=2:obj.m_ord
        Z = obj.m_series{k} * res.m_series{1};
        if k > 2
          coeffs = cellfun(@mtimes, obj.m_series(2:k-1), res.m_series(k-1:-1:2), 'UniformOutput', false);
          coeffsS = coeffs{1};
          for i=2:length(coeffs)
            coeffsS = coeffsS + coeffs{i};
          end
          Z = Z + coeffsS;
        end
        res.m_series{k} = linsolve(obj.m_series{1}, right.m_series{k} - Z, opts);
      end
    else
      sol = linsolve(obj.m_series{1}, right, opts);
      res = tseries2(sol);
      for k=2:obj.m_ord
        Z = obj.m_series{k} * res.m_series{1};
        if k > 2
          coeffs = cellfun(@mtimes, obj.m_series(2:k-1), res.m_series(k-1:-1:2), 'UniformOutput', false);
          coeffsS = coeffs{1};
          for i=2:length(coeffs)
            coeffsS = coeffsS + coeffs{i};
          end
          Z = Z + coeffsS;
        end
        res.m_series{k} = linsolve(obj.m_series{1}, -Z, opts);
      end
    end
  else
    sol = obj \ right.m_series{1};
    res = tseries2(sol);
    for k=2:res.m_ord
      res.m_series{k} = linsolve(obj, right.m_series{k}, opts);
    end
  end
end
