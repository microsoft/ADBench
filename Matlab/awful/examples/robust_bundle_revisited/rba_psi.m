function [r, r2] = rba_psi(t,w)
% RBA_PSI  Robust kernel from Zöllhöfer, Siggraph'14.
%           If called with 1 argument, it's the psi function,
%           With 2 args, it's kappa s.t. psi(t) = min_w kappa(t,w)
%           With 2 output args, it's [R1,R2] s.t. psi(t) = min_w |R(t,w)|^2

if nargin == 0
    %%
    ts = -3:.01:3;
    clf
    subplot(311)
    plot(ts, rba_psi(ts), 'k');
    axis([-3 3 -.1 1.1])
    
    ws = linspace(0,2,3000);
    [tts, wws] = meshgrid(ts, ws);
    f = rba_psi(tts, wws);
    hold on
    plot(ts, min(f), 'g--')
    
    subplot(312)
    dpsi = conv(rba_psi(ts),[-1 0 1],  'valid');
    plot(ts(2:end-1), dpsi, 'r');
    axis([-3 3 -.1 .1])
    
    subplot(313)
    ddpsi = conv(dpsi,[-1 0 1],  'valid');
    plot(ts(3:end-2), ddpsi, 'r');
    axis([-3 3 -.01 .01])
    return
end

if nargin == 1
    outliers = abs(t) > 1/sqrt(2);
    t2 = t.^2;
    r = 4*t2.*(1-t2);
    r(outliers) = 1;
    %grad = t*8-t*t2*16;
elseif nargin == 2
    if nargout == 1
        r = w.^2.*((t*2).^2) + (1 - w.^2).^2;
    else
        r = w.*t*2;
        r2 = 1 - w.^2;
    end
end
