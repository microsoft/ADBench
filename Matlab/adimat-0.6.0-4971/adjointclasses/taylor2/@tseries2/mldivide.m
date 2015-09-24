function obj = mldivide(obj, right)
  if isscalar(obj)
    obj = right ./ obj;
  else
    [m n] = size(obj);
    if m == n || (~admIsOctave() && m < n)
      obj = mldivide_square(obj, right);
    elseif m > n && strcmp(admGetPref('nonSquareSystemSolve'), 'fast')
      objt = obj';
      obj = mldivide_square(objt * obj, objt * right);
    else  
      obj = adimat_sol_qr(obj, right);
    end
  end
end
