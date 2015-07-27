function finite_diff_example

h = 1e-14;
while h(end)<1
    h(end+1) = h(end)*1.05;
end
lw = 1.5;

x = 10;
dy = FDfwd(x,h);
plot(log10(abs(dy-dfoo(x))),'linewidth',lw);
hold on

x = 0.1;
dy = FDfwd(x,h);
plot(log10(abs(dy-dfoo(x))),'linewidth',lw);

x = 0.001;
dy = FDfwd(x,h);
plot(log10(abs(dy-dfoo(x))),'linewidth',lw);


legend('x=10','x=0.1','x=0.001')
ylim([-16 4])
set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])

end

function dy = FDfwd(x,h)
dy = (foo(x+h)-foo(x))./h;
end

function y = foo(x)
y = x.^3;
end

function dy = dfoo(x)
dy=3*x.^2;
end