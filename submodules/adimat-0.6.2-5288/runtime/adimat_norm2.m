% function [r] = adimat_norm2(x, p)
%  
% Compute r = norm(x, p), for AD.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt

function [r] = adimat_norm2(x, p)

  % r = norm(x, p);
  
  if ischar(p) 
    if strcmp(lower(p), 'fro')
      r = sqrt(sum(x(:) .* conj(x(:))));
    else
      error('Only "fro" is a valid string for p-norm computation currently.');
    end
  else
    if isvector(x)
      if isinf(p)
        if p > 0
          r = max(abs(x));
        else
          r = min(abs(x));
        end
      else
        if isreal(x) && mod(p, 2) == 0
          answer = admGetPref('pnormEven_p_useAbs');
          if strcmp(answer, 'yes')
            a = abs(x);
          else
            a = x;
          end
        else
          a = abs(x);
        end
        r = sum(a .^ p) .^ (1/p);
      end
    elseif ismatrix(x)
      if isinf(p)
        a = abs(x);
        sa2 = sum(a,2);
        r = max(sa2);
        %       case -inf
        % matlab does not support it, octave does the same as
        % for +inf...
        %        r = norm(x, inf);
      elseif p == 2
%        if issparse(x)
%          % FIXME: use svds!
%          r = svds(x, 1);
%        else
          if issparse(x)
            x = full(x);
          end
          if isreal(x)
            s = svd(x);
          else
            [s] = adimat_svd(x);
          end
          r = max(s);
%        end
      elseif p == 1
        a = abs(x);
        sa2 = sum(a,1);
        r = max(sa2);
      else
        error('Derivatives of matrix-p-norm not implemented yet.');
      end
    else
      error('Value is neither a matrix nor a vector!');
    end
  end

end

% $Id: adimat_norm2.m 4281 2014-05-21 09:23:04Z willkomm $

