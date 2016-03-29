function m = mog_gallery(k)

% MOG_GALLERY   Get a typical mixture-of-gaussian
%               mog = mog_gallery(K) chooses a mixture
%               as follows.
%                1.  Pair of gently overlapping ones
%                3.  Triplet with 2 overlapping 

% Author: Andrew Fitzgibbon <awf@robots.ox.ac.uk>
% Date: 05 Nov 01

if nargin == 0
  test
  return
end

%%
switch k
case 1
  m(1).mean = [.3 .6];
  m(1).covariance = [1 0; 0 1]/10;
  m(1).weight = .5;

  m(2).mean = [.7 .4];
  R = planerot([.3 .4]');
  m(2).covariance = R * [1 0; 0 .5]/10 * R';
  m(2).weight = .5;

case 2
  m(1).mean = [.3 .8];
  m(1).covariance = [1 0; 0 1]/10;
  m(1).weight = .5;

  m(2).mean = [.7 .6];
  R = planerot([.3 .4]');
  m(2).covariance = R * [1 0; 0 .5]/10 * R';
  m(2).weight = .5;

  m(3).mean = [.7 .1];
  R = planerot([.4 -1]');
  m(3).covariance = R * [1 0; 0 .5]/10 * R';
  m(3).weight = .5;

case 3
  m(1).mean = [.3 .8];
  m(1).covariance = [1 0; 0 1]/10;
  m(1).weight = .5;

  m(2).mean = [.7 .6];
  R = planerot([.3 .4]');
  m(2).covariance = R * [1 0; 0 .5]/10 * R';
  m(2).weight = .5;

  m(3).mean = [.7 .5];
  R = planerot([.3 .4]');
  m(3).covariance = R * [1 0; 0 .5]/10 * R';
  m(3).weight = .5;

otherwise
  error('index out of range');
end

weight_sum = sum(cat(1, m.weight));
if weight_sum ~= 1
  for k=1:length(m)
    m(k).weight = m(k).weight / weight_sum;
  end
end

%%
function test
mog = mog_gallery(3);
clf
mog_ellipses(mog);
