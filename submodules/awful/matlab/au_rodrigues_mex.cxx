#include <au_mex.h>
#include <math.h>

void mlx_function(mlx_inputs& in, mlx_outputs& out)
{
  mlx_array<double> W(in[0]);
  mlx_assert(W.numel() == 3);

#define w(i) W[i-1]
  double w1 = w(1);
  double w2 = w(2);
  double w3 = w(3);

  double t2 = w2*w2;
  double t3 = w1*w1;
  double t4 = w3*w3;
  double t5 = t2+t3+t4;
  mlx_make_array<mlx_double> R(3,3);
  if (t5 == 0) {
    R[0] = R[4] = R[8] = 1.0;
    R[1] = R[2] = R[3] = 0.0;
    R[5] = R[6] = R[7] = 0.0;
  } else {
    double t7 = sqrt(t5);
    double t8 = cos(t7);
    double t10 = sin(t7);
    double t9 = t8-1.0;
    double t11 = 1.0/t7;
    double t13 = t10*t11*w2;

    double t6 = 1.0/t5;
    double t12 = t4*t6;
    double t14 = t3*t6;
    double t15 = t2*t6;
    double t17 = t12+t15;
    double t23 = t12+t14;
    double t32 = t14+t15;

    R[0] = t9*t17+1.0;
    R[3] = -t10*t11*w3-t6*t9*w1*w2;
    R[6] = t13-t6*t9*w1*w3;
	 
    R[1] = t10*t11*w3-t6*t9*w1*w2;
    R[4] = t9*t23+1.0;
    R[7] = -t10*t11*w1-t6*t9*w2*w3;
	 
    R[2] = -t13-t6*t9*w1*w3;
    R[5] = t10*t11*w1-t6*t9*w2*w3;
    R[8] = t9*t32+1.0;
  }
  out[0] = R;
}
