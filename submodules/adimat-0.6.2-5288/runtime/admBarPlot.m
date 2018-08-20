function ax = admBarPlot(values, names, figSize, fontSize, ax)
  if nargin < 3, figSize = [16 9]; end
  if nargin < 4, fontSize = 12; end
  if nargin < 5, ax = gca; end

  %  admSetFigProps(f, figSize, fontSize);

  bar(ax, values(:));
  set(ax, 'xticklabel', {});
  ylim = get(ax, 'ylim');
  valueTopOffset = 0.05;
  maxHeight = 0;
  for i=1:length(names)
%     h = text(i, values(i) + ylim(2).* valueTopOffset, ...
%              sprintf('%.3g', values(i)), ...
%              'interpreter', 'latex', ...
%              'fontweight', 'bold', ...
%              'BackgroundColor', [0.7 0.7 0.7], ...
%              'EdgeColor', [0.7 0.2 0.2], ...
%              'VerticalAlignment', 'middle', ...
%              'HorizontalAlignment', 'center', ...
%              'Color',[0 0 0] ...
%              );
% %    ext = get(h, 'extent');
% %    pos = get(h, 'position');
% %    pos(2) = pos(2) + ext(3);
% %    maxHeight = max(maxHeight, ext(3));
%     set(h, 'Rotation', 270);
% %    set(h, 'position', pos);
    
% %    ext = get(h, 'extent');
% %    pos = get(h, 'position')
% %    rectangle('position', [pos(1:2) ext(3:4)], 'FaceColor', 'r');
    
     h = text(i, -ylim(2) .* 0.01, names{i}, 'Rotation', 270, 'interpreter', 'latex', 'parent', ax);
  end
%  set(ax, 'ylim', [0 ylim(2) + );
  grid(ax, 'on');
  set(ax, 'outerposition', [0 0.08 1 0.92]);
%  set(ax, 'yscale', 'log');
end
% $Id: admBarPlot.m 4092 2014-05-01 17:48:21Z willkomm $
