function finite_diff_example

h = 1e-14;
while h(end)<1
    h(end+1) = h(end)*1.05;
end
lw = 1.5;

x = 1e6;
dyFD = FDfwd(x,h);
dy = dfoo(x);
plot(h,abs(dyFD-dy)/dy,'linewidth',lw);
hold on

x = 1;
dyFD = FDfwd(x,h);
dy = dfoo(x);
plot(h,abs(dyFD-dy)/dy,'linewidth',lw);

x = 1e-3;
dyFD = FDfwd(x,h);
dy = dfoo(x);
plot(h,abs(dyFD-dy)/dy,'linewidth',lw);


legend('x=1e6','x=1','x=1e-3','location', 'se')
set(gca,'fontsize',20,'xscale','log','yscale','log')
xlim([h(1) h(end)])
ylim([0 10e1])
xlabel('h')
ylabel('relative error')

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