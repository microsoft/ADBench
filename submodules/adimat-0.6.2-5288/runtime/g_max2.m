% function [g_r r] = g_max2(g_x, x, g_y, y)
%  
% Compute derivative of r = max(x, y).
%
% Copyright 2004-2008 André Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt

function [g_r r] = g_max2(g_x, x, g_y, y)
  r = max(x, y); 
  eqx = r== x; 
  eqy = r== y; 
  ties = eqx & eqy; 
  if any(ties(: ))
    warning('adimat:max:ties', 'There are %d ties in the max(x, y) evaluation.', sum(ties(: )));
  end
  % Ensure that if one argument is a scalar and one a matrix, the result is still correct.
  if isscalar(x)
    g_r= g_y; 
    if any(eqx(: )), 
      g_r(eqx)= g_x; 
    end
    if any(ties(: )), 
      g_r(ties)= (g_x+ g_y(ties)).* 0.5; 
    end
  else 
    g_r= g_x; 
    if any(eqy(: ))
      if isscalar(y)
        g_r(eqy)= g_y; 
        if any(ties(: ))
          g_r(ties)= (g_x(ties)+ g_y).* 0.5; 
        end
      else 
        g_r(eqy)= g_y(eqy); 
        if any(ties(: ))
          g_r(ties)= (g_x(ties)+ g_y(ties)).* 0.5; 
        end
      end
    end
  end
% $Id: g_max2.m 3727 2013-06-12 13:21:13Z willkomm $
