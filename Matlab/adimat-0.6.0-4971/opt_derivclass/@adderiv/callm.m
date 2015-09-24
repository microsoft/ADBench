function [varargout]= callm(f, varargin)
%ADDERIV/CALLM Call f with all arguments and results being derivative objects.

  % deal(): Copy argument to each result variable.
  [varargout{1:nargout}]= deal(adderiv(varargin{1}));

  % Prepare cellarray to store argument and results for i-th
  % directional derivative.
  nin= nargin-1;
  inp= cell(nin, 1);
  oup= cell(nargout, 1);

  % Loop over all directional derivatives.
  for i= 1: numel(varargin{1}.deriv)
    % Can not use deal() here, because varargin{:}.deriv is not
    % possible.
    for c= 1: nin
      inp{c}= varargin{c}.deriv{i};
    end
    % Call function f() for i-th directional derivative.
    [oup{:}]= f(inp{:});
    % Same as above
    for c= 1: nargout
      varargout{c}.deriv{i}= oup{c};
    end
  end
