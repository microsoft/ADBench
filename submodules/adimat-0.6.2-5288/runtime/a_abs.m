% function a_x = a_abs(a_z, x)
%
% Compute adjoint of z = abs(x), where a_z is the adjoint of z.
%
% see also a_zeros, a_mean
%
% Copyright (c) 2017 Johannes Willkomm
% Copyright (c) 2016 Johannes Willkomm
% Copyright (c) 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt

function a_x = a_abs(a_z, x)
  if isreal(x)
    lt0 = x < 0;
    if any(x == 0)
      warning('adimat:abs:argZero', '%s', 'a_abs(a_z, x) not defined for x==0.0');
    end
    a_x = a_z;
    a_x(lt0) = -a_x(lt0);
  else
    cabsmethod = admGetPref('complexAbs');
    switch cabsmethod
     case 'correctly'
      [a_r a_i] = a_hypot(a_z, real(x), imag(x));
      a_x = complex(real(a_r), -real(a_i));
      
     case 'as in fm'
      [a_r a_i] = a_hypot(a_z, real(x), imag(x));
      a_x = a_r;
      
     otherwise
      error('please set preference adimat/complexAbs to one of the allowed values')
    end

  end
