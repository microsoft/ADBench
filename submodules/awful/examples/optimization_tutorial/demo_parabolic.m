function [x, fcount] = demo_parabolic(f, a, c)

clf
xs = 0:.01:1;
plot(xs, f(xs), 'k');
axis([0 1 0 max(f(a), f(c))])
hold on

phi = (3 - sqrt(5))/2;

b = a + phi*(c-a);

h = plot(nan, 'ro', 'linewidth', 4);
h1 = plot(nan, 'bo', 'linewidth', 4);
h2 = plot(nan, 'b-', 'linewidth', 1);

fcount = 3;
while c-a > 1e-3
  title(sprintf('evaluations %d, fmin = %g', fcount, min(f([a b c]))));
  setxydata(h, [a b c], f([a b c]));
  setxydata(h1, nan, nan);
  pause
  
  % Choose next test point as min of parabola
  par = polyfit([a b c], f([a b c]), 2)
  setxydata(h2, xs, polyval(par, xs));
  
  x = -par(2)/par(1)/2;
  
  fcount = fcount + 1;
  setxydata(h1, x, f(x));
  pause

  % reject wild values
  if x < a, x = (a + b)/2; end
  if x > c, x = (b + c)/2; end
  if abs(x-b) < 1e-7, x = (b + c)/2; end
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
