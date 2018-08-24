function [varargout] = eig(a)
  assert(a.m_ord == 2, 'The eig methods supports first order derivatives only');
  if nargout == 1
    [V, D] = eig(a.m_series{1});
    l = tseries2(diag(D));
    l.m_series{2} = call(@diag, V \ (a.m_series{2} * V));
    varargout = {l};
  elseif nargout == 2
    [V, D] = eig(a.m_series{1});
    tmp = V \ (a.m_series{2} * V);
    tV = tseries2(V);
    tD = tseries2(D);
    tD.m_series{2} = call(@diag, call(@diag, tmp));
    tV.m_series{2} = V * (d_eig_F(diag(D)) .* tmp);
    varargout = {tV tD};
  end
end
% $Id: eig.m 4977 2015-05-08 10:21:53Z willkomm $
