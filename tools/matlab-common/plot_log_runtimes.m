% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function plot_log_runtimes( tools, times, xvals, title_, ylabel_,xlabel_)

lw = 2;
msz = 7;
[xvals, order] = sort(xvals);

figure; 
to_show = 1:numel(tools); % all
emphasized = [];
% emphasized = [11 17 22];
for i=to_show
    properties = {'linewidth',lw,'markersize',msz,...
            'color',tools(i).col,'marker',tools(i).marker};
    if tools(i).call_type == 6
        properties{end+1} = 'linestyle';
        properties{end+1} = '--';
    end
    if ismember(i,emphasized)
        properties{2} = 2*lw;
        properties{end+1} = 'markersize';
        properties{end+1} = 15;
    end
    loglog(xvals, times(order, i),properties{:});
    hold on
end

legend(tools(to_show).name, 'location', 'nw');
set(gca,'FontSize',14,'xscale','log','yscale','log')
xlim([min(xvals) max(xvals)])
title(title_)
xlabel(xlabel_);
ylabel(ylabel_)

end

