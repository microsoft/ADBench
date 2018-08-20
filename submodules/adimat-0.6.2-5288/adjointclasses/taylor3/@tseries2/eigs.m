function [varargout] = eigs(a, varargin)
  assert(a.m_ord == 2, 'The eig methods supports first order derivatives only');
  if nargout == 1
    [g_l, l] = g_eigs(a.m_series{2}, a.m_series{1}, varargin{:});
    l = tseries2(l);
    l.m_series{2} = g_l;
    varargout = {l};
  elseif nargout == 2
    [g_V, V, g_D, D] = g_eigs2(a.m_series{2}, a.m_series{1}, varargin{:});
    tV = tseries2(V);
    tD = tseries2(D);
    tV.m_series{2} = g_V;
    tD.m_series{2} = g_D;
    varargout = {tV tD};
  end
end
% $Id: eigs.m 5016 2015-05-19 21:33:29Z willkomm $
