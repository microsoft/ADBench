function w = au_rodrigues_rebase(w)
% AU_RODRIGUES_REBASE Scale vector by 2n pi so length in range [0,pi]
%                 Negative length changes sign of vector

if nargin == 0
  %% Test
  au_test_begin
  for k=[-5 -1 10]
    w = [1 2 k];
    au_test_equal au_rodrigues(w) au_rodrigues(au_rodrigues_rebase(w)) 1e-10
  end  
  w = [0 0 2*pi];
  au_test_equal au_rodrigues(w) au_rodrigues(au_rodrigues_rebase(w)) 1e-10
  w = [0 0 0];
  au_test_equal au_rodrigues(w) au_rodrigues(au_rodrigues_rebase(w)) 1e-10
  w = [1 1 1]/sqrt(3)*2*pi;
  au_test_equal au_rodrigues(w) au_rodrigues(au_rodrigues_rebase(w)) 1e-10
  au_test_end
  clear w
  return
end

au_assert_equal numel(w) 3
l = norm(w);
if l > pi
  l = (rem(l+pi, 2*pi)-pi)/l;
  w = w*l;
end
