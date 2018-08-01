import math
import numpy as np

def rotation_matrix_to_quaternion(R):
    nq = np.empty(4)
    t = R.trace()
    if (t >= 0.0):
        r = math.sqrt(1.0 + t)
        s = 0.5 / r
        nq[0] = 0.5 * r
        nq[1] = (R[2, 1] - R[1, 2]) * s
        nq[2] = (R[0, 2] - R[2, 0]) * s
        nq[3] = (R[1, 0] - R[0, 1]) * s
    elif R[0, 0] >= R[1, 1] and R[0, 0] >= R[2, 2]:
        r = math.sqrt(1.0 + R[0, 0] - R[1, 1] - R[2, 2])
        s = 0.5 / r
        nq[0] = (R[2, 1] - R[1, 2]) * s
        nq[1] = 0.5 * r
        nq[2] = (R[0, 1] + R[1, 0]) * s
        nq[3] = (R[2, 0] + R[0, 2]) * s
    elif R[1, 1] >= R[2, 2]:
        r = math.sqrt(1.0 - R[0, 0] + R[1, 1] - R[2, 2])
        s = 0.5 / r
        nq[0] = (R[0, 2] - R[2, 0]) * s
        nq[1] = (R[0, 1] + R[1, 0]) * s
        nq[2] = 0.5 * r
        nq[3] = (R[1, 2] + R[2, 1]) * s
    else:
        r = math.sqrt(1.0 - R[0, 0] - R[1, 1] + R[2, 2])
        s = 0.5 / r
        nq[0] = (R[1, 0] - R[0, 1]) * s
        nq[1] = (R[0, 2] + R[2, 0]) * s
        nq[2] = (R[1, 2] + R[2, 1]) * s
        nq[3] = 0.5 * r
    return nq

def quarterion_to_axis_angle(nq):
    axis = nq[1:4].copy()
    axis /= np.linalg.norm(axis)
    angle = math.acos(nq[0]) * 2
    return axis * angle

def rotation_matrix_to_axis_angle(R):
    return quarterion_to_axis_angle(rotation_matrix_to_quaternion(R))

cos = np.cos
sin = np.sin
# These rotations must be defined with a right-hand coordinate system, to match
# the rotation matrix computed by poseinfer::pose_params::joint
def Rx(tx):
   return np.array([[1,0,0], [0, cos(tx), -sin(tx)], [0, sin(tx), cos(tx)]])
def Ry(ty):
   return np.array([[cos(ty), 0, sin(ty)], [0, 1, 0], [-sin(ty), 0, cos(ty)]])
def Rz(tz):
    return np.array([[cos(tz), -sin(tz), 0], [sin(tz), cos(tz), 0], [0,0,1]]) 

def euler_angles_to_rotation_matrix(euler_angles, order='xyz'):
    R = np.eye(3)
    for theta, axis in zip(euler_angles, order):
        R = np.dot(R, dict(x=Rx, y=Ry, z=Rz)[axis](theta))

    return R

def angle_axis_to_rotation_matrix(angle_axis):
    angle_axis = angle_axis.copy()
    n = np.sqrt(np.sum(angle_axis**2))
    if n < .0001:
        return np.eye(3)

    angle_axis /= n
    x, y, z = angle_axis

    s, c = np.sin(n), np.cos(n)
    R = np.array([
            [x*x+(1-x*x)*c, x*y*(1-c)-z*s, x*z*(1-c)+y*s],
            [x*y*(1-c)+z*s, y*y+(1-y*y)*c, y*z*(1-c)-x*s],
            [x*z*(1-c)-y*s, z*y*(1-c)+x*s, z*z+(1-z*z)*c]])

    return R
