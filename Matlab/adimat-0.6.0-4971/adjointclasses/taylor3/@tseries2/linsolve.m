function obj = linsolve(obj, right, opts)
  if isscalar(obj)
    obj = right ./ obj;
  else
    [m n] = size(obj);
    if nargin < 3
      opts = struct();
      if m ~= n
        opts.RECT = true;
      end
    end
    if m == n || (~admIsOctave() && m < n)
      obj = linsolve_square(obj, right, opts);
    elseif m > n && strcmp(admGetPref('nonSquareSystemSolve'), 'fast')
      objt = obj';
      obj = linsolve_square(objt * obj, objt * right, opts);
    else  
      obj = adimat_sol_qr(obj, right);
    end
  end
end
