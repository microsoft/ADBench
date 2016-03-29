function M = au_cross_matrix(w)
% AU_CROSS_MATRIX Cross-product matrix of a vector
%              M = AU_CROSS_MATRIX(W) Creates the matrix
%                [  0 -w3  w2 ]
%                [ w3   0 -w1 ]
%                [-w2  w1   0 ]

% awf, 7/4/07
if nargin == 0
  % unit test
  a = randn(3,1);
  b = randn(3,1);
  au_test_equal cross_matrix(a)*b cross(a,b)
  return
end

M = [
   0    -w(3)  w(2) 
   w(3)    0  -w(1) 
  -w(2)  w(1)    0 
  ];
