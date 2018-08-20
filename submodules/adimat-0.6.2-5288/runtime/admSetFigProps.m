function admSetFigProps(f, figSize, fontSize)
  if nargin < 2, figSize = [16 9]; end
  if nargin < 3, fontSize = 10; end
  set(f, 'paperunits', 'centimeters');
  set(f, 'paperposition', [1 1 figSize]);
  set(f, 'defaulttextinterpreter', 'latex')
  set(f, 'defaultlinemarkersize', 6)
  set(f, 'defaultlinelinewidth', 0.5)
  set(f, 'defaultaxesunits', 'normalized');
  set(f, 'defaultaxesouterposition', [0 0 1 1]);
  set(f, 'defaultaxesfontunits', 'points');
  set(f, 'defaultaxesfontsize', fontSize);
  set(f, 'defaulttextfontsize', fontSize);
end
% $Id: admSetFigProps.m 3487 2012-12-13 21:49:20Z willkomm $
  
