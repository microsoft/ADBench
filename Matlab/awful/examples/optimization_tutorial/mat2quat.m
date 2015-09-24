function q = mat2exp( R )
% MAT2QUAT   Generates quaternion from rotation matrix 

% quaternion solution

q = [	(1 + R(1,1) + R(2,2) + R(3,3))
	(1 + R(1,1) - R(2,2) - R(3,3))
	(1 - R(1,1) + R(2,2) - R(3,3))
	(1 - R(1,1) - R(2,2) + R(3,3)) ];

[b I] = max(q);
q(I) = sqrt( b ) / 2 ;

if I == 1 
	q(2) = (R(3,2) - R(2,3)) / (4*q(I));
	q(3) = (R(1,3) - R(3,1)) / (4*q(I));
	q(4) = (R(2,1) - R(1,2)) / (4*q(I));
elseif I==2
	q(1) = (R(3,2) - R(2,3)) / (4*q(I));
	q(3) = (R(2,1) + R(1,2)) / (4*q(I));
	q(4) = (R(1,3) + R(3,1)) / (4*q(I));
elseif I==3
	q(1) = (R(1,3) - R(3,1)) / (4*q(I));
	q(2) = (R(2,1) + R(1,2)) / (4*q(I));
	q(4) = (R(3,2) + R(2,3)) / (4*q(I));
elseif I==4
	q(1) = (R(2,1) - R(1,2)) / (4*q(I));
	q(2) = (R(1,3) + R(3,1)) / (4*q(I));
	q(3) = (R(3,2) + R(2,3)) / (4*q(I));
end
