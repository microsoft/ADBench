function res= vertcat(varargin)
%ADDERIV/VERTCAT Concatenate derivatives vertically
%
% Copyright 2014 Johannes Willkomm
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if nargin==1 
   res= varargin{1};
elseif nargin == 2
   g1 = varargin{1};
   g2 = varargin{2};
   if isempty(g1)
     res= g2;
     return
   end
   if isempty(g2)
     res= g1;
     return
   end
   res = adderiv(g1);
   res.deriv = cellfun(@vertcat, g1.deriv, g2.deriv, 'UniformOutput', false);

else
  nempty = cellfun('isempty', varargin);
  args = varargin(~nempty);
  
  res = adderiv(args{1});
  d_cells = cellfun(@(x) x.deriv, args, 'UniformOutput', false);
  res.deriv = cellfun(@vertcat, d_cells{:}, 'UniformOutput', false);
  
end

% vim:sts=3:
