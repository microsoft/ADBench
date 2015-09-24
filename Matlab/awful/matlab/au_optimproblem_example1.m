function P = au_optimproblem_example1
% Bog-standard bundle adjustment:
%  K          fixed intrinsics across the sequence
%  Pose(1:n)  camera pose per frame
%  X(1:m)     3D points

%% Make params
Params = struct;
Params.Intrinsics.F = 1.0;
Params.Intrinsics.PP = [0 0]';
nFrames = 5;
for k=1:nFrames
  Params.Pose(k).R = [0 k/10 0]';
  Params.Pose(k).T = [0 0 -k]';
end
nPoints = 13;
Params.Points = rand(3,nPoints);

%%  Generate data
data = struct;
for k=1:nFrames
  X = au_rodrigues(Params.Pose(k).R) * [Params.Points] + au_bsx(Params.Pose(k).T);
  px = X(1:2,:) ./ X([3 3],:);
  mx = Params.Intrinsics.F * px + au_bsx(Params.Intrinsics.PP);
  mx = mx + randn(size(mx))*.01;
  subplot(3,3,k);
  data.Frames(k).XY = mx;
  plot(mx(1,:), mx(2,:), '.'); drawnow
end

%% Set up problem
P = au_optimproblem(Params);

P.Objective = @(OptimProblem) f(OptimProblem, data);
P.ComputeJacobPattern(2);
P.AddRebaser(@au_rodrigues_rebase, {P.Inds.Pose.R});
drawnow

%% Optimize, fixing first Camera's pose
profile on
P.ParamsToVary = {P.Inds.Intrinsics, P.Inds.Points, P.Inds.Pose(2:end)};
P.Optimize();
profile viewer

end

function f(OP, data)
nFrames = length(data.Frames);
for k=1:nFrames
  Pose = OP.Params.Pose(k);
  X = au_rodrigues_mex(Pose.R) * [OP.Params.Points] + au_bsx(Pose.T);
  px = X(1:2,:) ./ X([3 3],:);
  mx = OP.Params.Intrinsics.F * px + au_bsx(OP.Params.Intrinsics.PP);
  
  residuals = data.Frames(k).XY - mx;
  
  used_params = {OP.Inds.Intrinsics, OP.Inds.Pose(k), OP.Inds.Points};
  OP.AddResidualBlock(residuals, used_params);
end
end
