function h = mog_ellipses(mog, radii)

% MOG_ELLIPSES  Draw ellipses of a mixture-of-gaussians
%               ...

% Author: Andrew Fitzgibbon <awf@robots.ox.ac.uk>
% Date: 06 Nov 01

if nargin == 0
  test;
  return
end

if nargin < 2
  radii = [1];
end

%%
t = linspace(0,2*pi,100);
cx = cos(t);
cy = sin(t);
circle = [cx ; cy];
h=[];
holdval = get(gcf,'nextplot');
for r = radii
  for i=length(mog):-1:1
    colour = 'r';
    if exist('mog(i).colour','var')
      colour = mog(i).colour;
    end
    
    C = mog(i).mean(:);
    
    if ~isnan(sum(C)) & (cond(mog(i).covariance) < 1e6)
      
      % h(i, 2) = plot(C(1), C(2), 'o', 'linewidth', 1, 'color', colour);
      hold on
      [V D] = eig(mog(i).covariance);
      
      ell = V * sqrt(D) * r * circle;
      h(end+1) = plot(ell(1,:) + C(1), ell(2,:) + C(2));
      set(h(end), 'color', colour, 'linewidth', 2)
      hold on
    end
  end
end
set(gcf, 'nextplot', holdval);

%%
function test
mog = mog_gallery(2);
clf
axis([-1 2 -.5 1.5]);
mog_ellipses(mog, 1);
