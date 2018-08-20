function res= cat(dim, varargin)
%ADDERIV/HORZCAT Concatenate gradients along dim
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
   res = adderivsp(g1);
   for k=1:length(g1)
     res.deriv{k} = cat(dim, g1.deriv{k}, g2.deriv{k});
   end

else
  nempty = cellfun('isempty', varargin);
  args = varargin(~nempty);
  
  res = adderivsp(args{1});
  d_cells = cellfun(@(x) x.deriv, args, 'UniformOutput', false);
  res.deriv = cellfun(@(varargin) cat(dim, varargin{:}), d_cells{:}, 'UniformOutput', false);
  
end

% vim:sts=3:
