function au_quat2mat_test

au_test_begin au_quat2mat
R = q2m([1 0 0 0]);
au_test_equal R au_quat2mat([1,0,0,0]')
R = q2m([0 1 0 0]);
au_test_equal R au_quat2mat([0,1,0,0]')
R = q2m([1 2 eps 0]);
au_test_equal R au_quat2mat([1,2,eps,0]')
au_test_end

end

function R = q2m(q)
q00 = q(1)*q(1); q0x = q(1)*q(2); q0y = q(1)*q(3); q0z = q(1)*q(4);
qxx = q(2)*q(2); qxy = q(2)*q(3); qxz = q(2)*q(4);
qyy = q(3)*q(3); qyz = q(3)*q(4);
qzz = q(4)*q(4);

R = [ q00 + qxx - qyy - qzz       2*(qxy - q0z)	          2*(qxz + q0y)
      2*(qxy + q0z)       q00 - qxx + qyy - qzz       2*(qyz - q0x)
      2*(qxz - q0y)	          2*(qyz + q0x)	      q00 - qxx - qyy + qzz ];
end
