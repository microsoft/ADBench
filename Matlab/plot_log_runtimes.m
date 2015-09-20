function plot_log_runtimes( tools, times, xvals, title_, ylabel_,...
    do_plot_linear_quadratic_complexity)

% set(groot,'defaultAxesColorOrder',...
%     [.8 .1 0;0 .7 0;.2 .2 1; 0 0 0; .8 .8 0],...
%     'defaultAxesLineStyleOrder', '-|s-|x-|^-')
% 
% % ordering
% [tmp,preorder]=sort(times_J,2);
% preorder(isinf(tmp)) = NaN;
% scores=zeros(ntools,1);
% mask=~isnan(preorder);
% tmp=repmat(fliplr((1:ntools)),ntasks,1);
% scores(preorder(mask)) = scores(preorder(mask)) + tmp(mask);
% [~, order] = sort(scores);

lw = 2;
msz = 7;
[xvals, order] = sort(xvals);

figure; 
to_show = 1:numel(tools); % all
% to_show=[1 2 3 4 10 11 14 16 18 19 20 21 22]; % unique languages for gmm
% to_show = [1:3 4:2:9 10:14 16 18 19 21:23]; % gmm non-split
% to_show = [1:4 6:8 10:numel(tools)]; % gmm 1k to show
% to_show = [1:4 6:numel(tools)]; % gmm 10k to show
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

% if do_plot_linear_quadratic_complexity
%     a = [min(x) max(x)];
%     plot(a,a/10000,'color',[.7 .7 .7])
%     plot(a,a.^2/50000,'color',[.7 .7 .7])
% end

legend(tools(to_show).name, 'location', 'nw');
set(gca,'FontSize',14,'xscale','log','yscale','log')
xlim([min(xvals) max(xvals)])
title(title_)
% title('Gradient Absolute Runtimes - 1k Data Points')
% title('Gradient Relative Runtimes - 2.5M Data Points^{[Zoran & Weiss, ICCV 11]}')
xlabel('# nonzero entries')
% xlabel('# parameters')
ylabel(ylabel_)

end

