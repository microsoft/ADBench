function [x, fcount] = demo_bisection(f, a, c, phi)

clf
set(1, 'defaultLineLineSmoothing', 'on')
xs = 0:.01:1;
plot(xs, f(xs), 'k');
axis([0 1 0 max(f(a), f(c))*1.1])
hold on

if nargin < 4
  phi = (3 - sqrt(5))/2;
end
b = a + phi*(c-a);

h = plot(nan, 'ro', 'linewidth', 4);
h1 = plot(nan, 'bo', 'linewidth', 4);

fcount = 3;
while c-a > 1e-3
  title(sprintf('evaluations %d, fmin = %g', fcount, min(f([a b c]))));
  setxydata(h, [a b c], f([a b c]));
  setxydata(h1, nan, nan);
  pause
  
  % Choose next test point in the longest interval
  if (c-b) > (b-a)
    x = b + phi*(c-b);
  else
    x = a + phi*(b-a);
  end

  fcount = fcount + 1;
  setxydata(h1, x, f(x));
  pause

  % Sort into a,b,x,c order
  if x < b, [b x] = deal(x,b); end
  % Choose next triplet
  isVshaped = @(f,g,h) (g < f) && (g < h);
  if isVshaped(f(a), f(b), f(x))
    [a,b,c] = deal(a,b,x);
  else % Vshaped in b x c
    [a,b,c] = deal(b,x,c);
  end
  
end
