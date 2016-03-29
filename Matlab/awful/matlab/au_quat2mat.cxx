#include <au_mex.h>

void mlx_function(mlx_inputs& in, mlx_outputs& out)
{
  mlx_array<double> Q(in[0]);
  mlx_assert(Q.numel() == 4);

#define q(i) Q[i-1]
  double q00 = q(1)*q(1); 
  double q0x = q(1)*q(2); 
  double q0y = q(1)*q(3); 
  double q0z = q(1)*q(4);

  double qxx = q(2)*q(2); 
  double qxy = q(2)*q(3); 
  double qxz = q(2)*q(4);

  double qyy = q(3)*q(3); 
  double qyz = q(3)*q(4);

  double qzz = q(4)*q(4);

  mlx_make_array<mlx_double> R(3,3);
  
  R[0] = q00 + qxx - qyy - qzz;
  R[3] = 2*(qxy - q0z);
  R[6] = 2*(qxz + q0y);
  R[1] = 2*(qxy + q0z);
  R[4] = q00 - qxx + qyy - qzz;
  R[7] = 2*(qyz - q0x);
  R[2] = 2*(qxz - q0y);
  R[5] = 2*(qyz + q0x);
  R[8] = q00 - qxx - qyy + qzz;

  out[0] = R;
}
