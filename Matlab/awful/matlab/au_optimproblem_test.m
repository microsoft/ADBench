function au_optimproblem_test

%% Build params
rng(43);
Params = struct;
nCameras = 2;
for k=1:nCameras
  Params.Cameras(k).F = 1.0;
  Params.Cameras(k).R = [0 0 0]';
  Params.Cameras(k).T = [0 0 k]';
end
nFrames = 3;
Params.Sphere.Radius = 0.10;
for k=1:nFrames
  Params.Frames(k).SphereCentre = [0 0 0]';
end

%%  Generate data
data = struct;
for k=1:nFrames
  for c=1:nCameras
    data.Frames(k).Cameras(c).XY = randn(2,10*k) + au_bsx([10*k, 0]');
  end
end

%% Set up problem
P = au_optimproblem(Params);

P.Objective = @(OptimProblem) f(OptimProblem, data);
P.ComputeJacobPattern(1);


%% Optimize over a subset of parameters
P.ParamsToVary = {P.Inds.Cameras, P.Inds.Frames(1)};
P.Display = 'final';
P.TolFun = 1e-5;
P.TolX = 1e-5;
P.MaxFunEvals = 1000;
P.Optimize();

%% And now all parameters
P.ParamsToVary = P.Inds;
P.Display = 'iter';
P.Optimize();

%% And now all parameters
P.Display = 'none';
fprintf('Test for silence....');
P.Optimize();
fprintf(' was it?\n');

%% Test Ctrl+C
P.Params = Params;
P.ParamsToVary = P.Inds;
P.Display = 'iter';
P.SaveFile = 'c:\tmp\au_optimproblem_savefile.mat';
fprintf('Test for Ctrl-C....');
if exist(P.SaveFile, 'file')
  fprintf(' [found %s from last time\n', P.SaveFile);
  fprintf('  you should see a restart at last printed value]');
  s = load(P.SaveFile);
  P.Params = s.tmpParams;  % should restart where it was...
end
fprintf('\n');
P.Objective = @(OP) f_slow(OP, data);
P.Optimize();
if exist(P.SaveFile, 'file')
  delete(P.SaveFile); % So the savefile will be gone if there's a successful exit
end

end

%% Objective function.
% Takes an optimproblem and calls AddResidualBlock several times.
% After the first call, this is quite fast, because everything has been
% appropriately sized.  The larger your residual blocks, the faster it
% will be, but the coarser your JacobPattern will be.
function f(OP, data)
nFrames = length(data.Frames);
nCameras = length(OP.Params.Cameras);
for k=1:nFrames
  for c=1:nCameras
    Cam = OP.Params.Cameras(c);
    SphereCentre = OP.Params.Frames(k).SphereCentre;
    
    X = au_rodrigues(Cam.R) * SphereCentre + Cam.T;
    px = Cam.F*X(1:2)/X(3);
    mx = data.Frames(k).Cameras(c).XY;
    residuals_block = au_bsx(px) - mx;
    OP.AddResidualBlock(residuals_block);
    
    if OP.WantBlockInfo
      % Caller is asking us which parameters we used to compute
      % the block of residuals we just added.
      used_params = {OP.Inds.Cameras(c), OP.Inds.Frames(k).SphereCentre};
      OP.AddResidualBlockInfo(used_params);
    end
  end
end
end

function f_slow(OP, data)
pause(0.1);
f(OP, data);
end
