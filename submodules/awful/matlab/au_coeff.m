function coeffs = au_coeff(symexpr, var)
% AU_COEFF    Extract polynomial coefficients from symbolic expr
%              coeffs = au_COEFF(a + b*x + c*x^6, x)

if nargin == 0
  %% Test
  syms a b c x real
  au_coeff(b*x + c*x^6, x)
  return
end
  
coeffs = feval(symengine, 'coeff', symexpr, var, 'All');
