vec = @(x) x(:);

%%
X = rand(3, 20);
axis_gt = orth(randn(3,1));
angle_gts = [0:45:315 352:2:368 405];
angle_gts = [85:95];
for REBASE = 0:1
  for QUAT = [true ]
    if QUAT
      p2rot = @(x) quat2mat(x/norm(x));
      w0 = zeros(4,1);
    else
      p2rot = @au_rodrigues;
      w0 = zeros(3,1);
    end
    
    OP = au_optimproblem(w0);
    OP.Display = 'none';
    OP.MaxFunEvals = 200;
    OP.TolFun = 1e-6;
    NSAMPLES = 200/5;
    
    p2rot
    All= [];
    for i = 1:length(angle_gts)
      angle_gt = angle_gts(i)*pi/180;
      R = au_rodrigues(axis_gt, angle_gt);
      
      Noise = randn(size(X))*0.01;
      
      Y = R * X + Noise;
      
      rebase_angle = @(x) (rem(x+pi, 2*pi)-pi)/x;
      rebase_exp = @(x) x*rebase_angle(norm(x));
      rebase_quat = @(x) x / norm(x);
      
      err = @(x) vec(Y - p2rot(x)*X);
      OP.Objective = @(OP) OP.AddResidualBlock(err(OP.Params));
      OP.Optimizer = 'au';
      if REBASE
        if QUAT
          OP.AddRebaser(@(x) rebase_quat(x), {OP.Inds});
        else
          OP.AddRebaser(@(x) rebase_exp(x), {OP.Inds});
        end
      end
      
      clear Results
      for k=1:NSAMPLES
        RandRot = au_rodrigues(randn(3,1)*.1);
        axis0 = RandRot*axis_gt;
        angle0 = angle_gt + 10*pi/180*(rand*2-1);
        if QUAT
          OP.Params = mat2quat(au_rodrigues(axis0*angle0));
        else
          OP.Params = axis0*angle0;
        end
        OP.Optimize();
        Results(k) = OP.Info;
      end
      iters = [Results.Iters];
      All(i,:) = iters;
      fvals = [Results.FVal];
      nmins = sum(fvals <= 1.0001*min(fvals));
      fprintf('%5d a=%8g mins %d, iter=%g+/-%g\n', ...
        i, angle_gts(i), nmins, mean(iters), std(iters));
      
    end
    if REBASE
      if QUAT
        AllQRebase = All;
      else
        AllERebase = All;
      end
    else
      if QUAT
        AllQ = All;
      else
        AllE = All;
      end
    end
    %%
    clf
    boxplot(All', angle_gts)
    title(sprintf('quat=%d rebase=%d', QUAT, REBASE));
    drawnow
  end
end

%%
p = @(x,y,varargin) errorbar(x, mean(y), std(y), varargin{:});
hold off
h(1)=p(angle_gts, AllE','r.-', 'DisplayName', 'Exp');
hold on
h(2)=p(angle_gts, AllQ','k.-', 'DisplayName', 'Quat');
h(4)=p(angle_gts, AllQRebase','b.-', 'DisplayName', 'QuatRebase');
h(3)=p(angle_gts, AllERebase','m.-', 'DisplayName', 'ExpRebase');
legend(h, 'Location', 'nw')
xlabel('Ground truth rotation angle')
ylabel('Mean #iterations')
set(gca, 'xtick', 0:45:360+45)
return

%%
hold off
h(1)=errorbar(angle_gts, mean(AllE'), std(AllE')/4,'r', 'DisplayName', 'Exp');
hold on
h(2)=errorbar(angle_gts, mean(AllQ'), std(AllQ')/4,'k', 'DisplayName', 'Quat');
legend(h, 'Location', 'nw')
xlabel('Ground truth rotation angle')
ylabel('Mean #iterations')
