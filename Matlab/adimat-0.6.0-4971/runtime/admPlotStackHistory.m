function [r_figures] = admPlotStackHistory(stackInfo, admOpts, tF)
  persistent legends1 legends2 figures maxSize maxItems minX maxX

  if nargin == 1
    fprintf(1, 'load result data from file: %s\n', stackInfo);
    s = load(stackInfo);
    stackInfo = s.stackInfo;
    admOpts = s.admOpts;
    tF = s.tF;
  end
  
  rev = adimat_version(4);
  revN = str2num(rev);
  if isempty(revN), revN = 0; end
  if isempty(figures)
    figures = revN + [1, 2];
    try
      for i=1:4
        close(figures(i));
      end
    catch
    end
  end
  
  stackName = admOpts.stack;
  style = '.';
  styleSizes = '.';
  switch stackName
   case {'matlab-file', 'octave-file'}
    color = 'r';
   case {'matlab-abuffered-file', 'octave-abuffered-file', ...
         'matlab-abuffered-file-aio'}
    color = 'g';
   case {'matlab-sstream', 'octave-sstream'}
     color = 'b';
   case {'matlab-mem', 'octave-mem'}
    color = 'c';
   case 'null'
    color = 'm';
    styleSizes = '-+';
   case 'native-cell'
    color = 'y';
   otherwise
    color = 'k';
  end
  
  n = length(stackInfo);
  mid = floor(n / 2) + 1;
  plotxs = zeros(1, n);
  sizesN = zeros(1, n);
  sizesMB = zeros(1, n);

  for i=1:n
    plotxs(i) = stackInfo{i}{3};
    sizesN(i) = stackInfo{i}{4};
    sizesMB(i) = stackInfo{i}{5};
  end
  plotxs = plotxs .* 3600 .* 24;
  sizesMB = sizesMB ./ 2^20;

  plotxs = plotxs - plotxs(mid);

  if isempty(maxItems)
    maxItems = sizesN(mid);
    minX = min(plotxs);
    maxX = max(plotxs);
  else
    maxItems
    sizesN(mid)
    assert(maxItems == sizesN(mid));
    minX = min(minX, min(plotxs));
    maxX = max(maxX, max(plotxs));
  end
  
  markerSize = 1;
  markerSizeSizes = markerSize;
  markerSizeLegend = 10;
  lineWidth = 1;
  
  if strcmp(stackName, 'null') || strcmp(stackName, 'native-cell')
    if isempty(maxSize)
      error('stacks null or native-cell must not be plotted first');
    end
    plotxsSizes = [plotxs(1) plotxs(mid)]
    sizesMB = [0 maxSize]
    nSizes = 3;
    midSizes = 2;
    markerSizeSizes = 3;
  else  
    plotxsSizes = plotxs;
    midSizes = mid;
    nSizes = n;
    if isempty(maxSize)
      maxSize = sizesMB(mid);
    else
      assert(maxSize == sizesMB(mid) || sizesMB(mid) == 0);
    end
  end
  
  if isempty(legends1)
    legends1 = {};
    legends2 = {};
  end
  legendEntry = sprintf('%s, %d x %s', stackName, ...
                        admOpts.stackOptions.numBuffers, ...
                        dataSize(admOpts.stackOptions.bufferSize));
  
  figure(figures(1)), hold on
  hits = strfind(legends1, 'ideal');
  haveOrigLine = isempty(cat(1, hits{:}));
  if maxSize > 0 && haveOrigLine
    line([-tF, 0, 3 .* tF], [0, maxSize, 0], 'color', 'black');
    legends1{end+1} = 'ideal';
    legends2{end+1} = 'ideal';
  end
  set(gca, 'DefaultLineMarkerSize', markerSizeSizes);
  set(gca, 'DefaultLineLineWidth', lineWidth);
  if any(sizesMB ~= 0)
    plot(plotxsSizes, sizesMB, [styleSizes color]);
    legends1{end+1} = legendEntry;
  end
  legends2{end+1} = legendEntry;
  %set(gca, 'xscale', 'log');
  %set(gca, 'yscale', 'log');
  xlabel('t (s)');
  ylabel('d (MB)');
  title('size of stack in bytes');
  l=legend(legends1, 'location', 'northeast');
  a=get(l,'children');
  set(a(1:3:end),'markersize',markerSizeLegend); % This line changes the legend marker size
  
  
  figure(figures(2)), hold on
  if maxSize > 0 && haveOrigLine
    line([-tF, 0, 3 .* tF], [0, maxItems, 0], 'color', 'black');
  end
  set(gca, 'DefaultLineMarkerSize', markerSize);
  set(gca, 'DefaultLineLineWidth', lineWidth);
  plot(plotxs, sizesN, [style color]);
  %set(gca, 'xscale', 'log');
  %set(gca, 'yscale', 'log');
  xlabel('t (s)');
  ylabel('items');
  title('size of stack in number of items');
  set(gca, 'DefaultLineMarkerSize', 10);
  l = legend(legends2, 'location', 'northeast');
  a=get(l,'children');
  set(a(1:3:end),'markersize',markerSizeLegend); % This line changes the legend marker size
 
  ax(1) = get(figures(1), 'currentaxes');
  ax(2) = get(figures(2), 'currentaxes');

  xlims = [ minX, maxX ]
  set(ax(1), 'xlim', xlims);
  set(ax(2), 'xlim', xlims);
  
%  fprintf(1, 'write speed: %g MB/s %g push/s\n', sizesMB(midSizes) ./ -plotxs(1),sizesN(mid) ./ -plotxs(1));
%  fprintf(1, 'read speed: %g MB/s %g pop/s\n', sizesMB(midSizes) ./ plotxs(end), sizesN(mid) ./ plotxs(end));

  r_figures = figures;
end
function s = dataSize(n)
  if n >= 2^30
    s = sprintf('%g GB', n ./ 2^30);
  elseif n >= 2^20
    s = sprintf('%g MB', n ./ 2^20);
  elseif n >= 2^10
    s = sprintf('%g kB', n ./ 2^10);
  else
    s = sprintf('%g B', n);
  end
end