function rba_figures

ts = -3:0.02:3;
ws = linspace(0,2,3000);
[tts, wws] = meshgrid(ts, ws);
f = rba_psi(tts, wws);

clf
subplot(212)
plot(ts, rba_psi(ts), 'k')
hold on
plot(ts, min(f), 'ro', 'markersize', 2);

axis([-3 3 0 1.1])

%%
subplot(211)
wmin = 0.01;
ts = linspace(-3, 3, 200);
ws = linspace(wmin,2.5,100);
[tts, wws] = meshgrid(ts, ws);
f = rba_psi(tts, wws);
hold off
contour(tts, wws, f, 2.^(-5:.9:8), 'b'), 
hold on, 
[~, minind] = min(f);

plot(ts, ws(minind), '-', 'color', [0 1 0]/2)

s=.1;
ts = -3:s:3;
ws = 0:s:2.5;
[tts, wws] = meshgrid(ts, ws);
f = rba_psi(tts, wws);
[px,py] = gradient(f,ts,ws); 
n=sqrt(px.^2+py.^2); 
scale = 1./n;
p=quiver(tts, wws, -px.*scale,-py.*scale, .5, 'k');
set(p, 'color', [1 1 1]*.7)
xlabel r
ylabel w
axis([-3 3 0 2.5])

legend('contours of \kappa', 'argmin_w \kappa(w,t)')
